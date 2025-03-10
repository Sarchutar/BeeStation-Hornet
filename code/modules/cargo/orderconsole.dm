/obj/machinery/computer/cargo
	name = "supply console"
	desc = "Used to order supplies, approve requests, and control the shuttle."
	icon_screen = "supply"
	circuit = /obj/item/circuitboard/computer/cargo

	//Can the supply console send the shuttle back and forth? Used in the UI backend.
	var/can_send = TRUE
	var/requestonly = FALSE
	//Can you approve requests placed for cargo? Works differently between the app and the computer.
	var/can_approve_requests = TRUE
	var/contraband = FALSE
	var/self_paid = FALSE
	var/safety_warning = "For safety and ethical reasons, the automated supply shuttle \
		cannot transport live organisms, human remains, classified nuclear weaponry, \
		homing beacons, mail, or machinery housing any form of artificial intelligence."
	var/blockade_warning = "Bluespace instability detected. Shuttle movement impossible."
	/// radio used by the console to send messages on supply channel
	var/obj/item/radio/headset/radio
	/// var that tracks message cooldown
	var/message_cooldown
	COOLDOWN_DECLARE(order_cooldown)

	light_color = "#E2853D"//orange

/obj/machinery/computer/cargo/request
	name = "supply request console"
	desc = "Used to request supplies from cargo."
	icon_screen = "request"
	circuit = /obj/item/circuitboard/computer/cargo/request
	can_send = FALSE
	can_approve_requests = FALSE
	requestonly = TRUE

/obj/machinery/computer/cargo/Initialize(mapload)
	. = ..()
	radio = new /obj/item/radio/headset/headset_cargo(src)
	RegisterSignal(SSdcs, COMSIG_GLOB_RESUPPLY, PROC_REF(update_static_ui))

/obj/machinery/computer/cargo/Destroy()
	QDEL_NULL(radio)
	return ..()

/obj/machinery/computer/cargo/proc/update_static_ui()
	for (var/datum/tgui/open_window as() in SStgui.get_all_open_uis(src))
		update_static_data(null, open_window)

/obj/machinery/computer/cargo/proc/get_export_categories()
	. = EXPORT_CARGO
	if(contraband)
		. |= EXPORT_CONTRABAND
	if(obj_flags & EMAGGED)
		. |= EXPORT_EMAG

/obj/machinery/computer/cargo/on_emag(mob/user)
	..()
	user?.visible_message(span_warning("[user] swipes a suspicious card through [src]!"),
		span_notice("You adjust [src]'s routing and receiver spectrum, unlocking special supplies and contraband."))

	contraband = TRUE

	// This also permamently sets this on the circuit board
	var/obj/item/circuitboard/computer/cargo/board = circuit
	board.contraband = TRUE
	board.obj_flags |= EMAGGED
	update_static_data(user)

/obj/machinery/computer/cargo/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/cargo/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Cargo")
		ui.open()
		ui.set_autoupdate(TRUE) // Account balance, shuttle status

/obj/machinery/computer/cargo/ui_data()
	var/list/data = list()
	data["location"] = SSshuttle.supply.getStatusText()
	var/datum/bank_account/D = SSeconomy.get_budget_account(ACCOUNT_CAR_ID)
	if(D)
		data["points"] = D.account_balance
	data["away"] = SSshuttle.supply.getDockedId() == "supply_away"
	data["self_paid"] = self_paid
	data["docked"] = SSshuttle.supply.mode == SHUTTLE_IDLE
	data["loan"] = !!SSshuttle.shuttle_loan
	data["loan_dispatched"] = SSshuttle.shuttle_loan && SSshuttle.shuttle_loan.dispatched
	data["can_send"] = can_send
	data["can_approve_requests"] = can_approve_requests
	var/message = "Remember to stamp and send back the supply manifests."
	if(SSshuttle.centcom_message)
		message = SSshuttle.centcom_message
	if(SSshuttle.supplyBlocked)
		message = blockade_warning
	data["message"] = message
	data["cart"] = list()
	for(var/datum/supply_order/SO in SSsupply.shoppinglist)
		data["cart"] += list(list(
			"object" = SO.pack.name,
			"cost" = SO.pack.get_cost(),
			"supply" = SO.pack.current_supply,
			"id" = SO.id,
			"orderer" = SO.orderer,
			"paid" = !isnull(SO.paying_account) //paid by requester
		))

	data["requests"] = list()
	for(var/datum/supply_order/SO in SSsupply.requestlist)
		data["requests"] += list(list(
			"object" = SO.pack.name,
			"cost" = SO.pack.get_cost(),
			"supply" = SO.pack.current_supply,
			"orderer" = SO.orderer,
			"reason" = SO.reason,
			"id" = SO.id
		))

	return data

/obj/machinery/computer/cargo/ui_static_data(mob/user)
	var/list/data = list()
	data["requestonly"] = requestonly
	data["supplies"] = list()
	for(var/pack in SSsupply.supply_packs)
		var/datum/supply_pack/P = SSsupply.supply_packs[pack]
		if(!data["supplies"][P.group])
			data["supplies"][P.group] = list(
				"name" = P.group,
				"packs" = list()
			)
		if((P.hidden && !(obj_flags & EMAGGED)) || (P.contraband && !contraband) || (P.special && !P.special_enabled) || P.DropPodOnly)
			continue
		data["supplies"][P.group]["packs"] += list(list(
			"name" = P.name,
			"cost" = P.get_cost(),
			"id" = pack,
			"supply" = P.current_supply,
			"desc" = P.desc || P.name, // If there is a description, use it. Otherwise use the pack's name.
			"small_item" = P.small_item,
			"access" = P.access
		))
	return data

/obj/machinery/computer/cargo/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	switch(action)
		if("send")
			if(!SSshuttle.supply.canMove())
				say(safety_warning)
				return
			if(SSshuttle.supplyBlocked)
				say(blockade_warning)
				return
			if(SSshuttle.supply.getDockedId() == "supply_home")
				SSshuttle.supply.export_categories = get_export_categories()
				SSshuttle.moveShuttle("supply", "supply_away", TRUE)
				say("The supply shuttle is departing.")
				usr.investigate_log(" sent the supply shuttle away.", INVESTIGATE_CARGO)
			else
				usr.investigate_log(" called the supply shuttle.", INVESTIGATE_CARGO)
				say("The supply shuttle has been called and will arrive in [SSshuttle.supply.timeLeft(600)] minutes.")
				SSshuttle.moveShuttle("supply", "supply_home", TRUE)
			. = TRUE
		if("loan")
			if(!SSshuttle.shuttle_loan)
				return
			if(SSshuttle.supplyBlocked)
				say(blockade_warning)
				return
			else if(SSshuttle.supply.mode != SHUTTLE_IDLE)
				return
			else if(SSshuttle.supply.getDockedId() != "supply_away")
				return
			else
				SSshuttle.shuttle_loan.loan_shuttle()
				say("The supply shuttle has been loaned to CentCom.")
				. = TRUE
		if("add")
			if(!COOLDOWN_FINISHED(src, order_cooldown))
				return
			var/id = text2path(params["id"])
			var/datum/supply_pack/pack = SSsupply.supply_packs[id]
			if(!istype(pack))
				return
			if((pack.hidden && !(obj_flags & EMAGGED)) || (pack.contraband && !contraband) || pack.DropPodOnly)
				return

			var/name = "*None Provided*"
			var/rank = "*None Provided*"
			var/ckey = usr.ckey
			if(ishuman(usr))
				var/mob/living/carbon/human/H = usr
				name = H.get_authentification_name()
				rank = H.get_assignment(hand_first = TRUE)
			else if(issilicon(usr))
				name = usr.real_name
				rank = "Silicon"

			var/datum/bank_account/account
			if(self_paid && ishuman(usr))
				var/mob/living/carbon/human/H = usr
				var/obj/item/card/id/id_card = H.get_idcard(TRUE)
				if(!istype(id_card))
					say("No ID card detected.")
					return
				account = id_card.registered_account
				if(!istype(account))
					say("Invalid bank account.")
					return

			var/reason = ""
			if(requestonly && !self_paid)
				reason = stripped_input(usr, "Reason:", name, "")
				if(!reason)
					return
				if(CHAT_FILTER_CHECK(reason))
					to_chat(usr, span_warning("You cannot send a message that contains a word prohibited in IC chat!"))
					return

			var/turf/T = get_turf(src)
			var/datum/supply_order/SO = new(pack, name, rank, ckey, reason, account)
			SO.generateRequisition(T)
			if(requestonly && !self_paid)
				SSsupply.requestlist += SO
			else
				SSsupply.shoppinglist += SO
				if(self_paid)
					say("Order processed. The price will be charged to [account.account_holder]'s bank account on delivery.")
			if(requestonly && message_cooldown < world.time)
				radio.talk_into(src, "A new order has been requested.", RADIO_CHANNEL_SUPPLY)
				message_cooldown = world.time + 30 SECONDS
			. = TRUE
		if("remove")
			var/id = text2num(params["id"])
			for(var/datum/supply_order/SO in SSsupply.shoppinglist)
				if(SO.id == id)
					SSsupply.shoppinglist -= SO
					. = TRUE
					break
		if("clear")
			SSsupply.shoppinglist.Cut()
			. = TRUE
		if("approve")
			var/id = text2num(params["id"])
			for(var/datum/supply_order/SO in SSsupply.requestlist)
				if(SO.id == id)
					SSsupply.requestlist -= SO
					SSsupply.shoppinglist += SO
					. = TRUE
					break
		if("deny")
			var/id = text2num(params["id"])
			for(var/datum/supply_order/SO in SSsupply.requestlist)
				if(SO.id == id)
					SSsupply.requestlist -= SO
					. = TRUE
					break
		if("denyall")
			SSsupply.requestlist.Cut()
			. = TRUE
		if("toggleprivate")
			self_paid = !self_paid
			. = TRUE
	if(.)
		post_signal("supply")

/obj/machinery/computer/cargo/proc/post_signal(command)

	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)

	if(!frequency)
		return

	var/datum/signal/status_signal = new(list("command" = command))
	frequency.post_signal(src, status_signal)
