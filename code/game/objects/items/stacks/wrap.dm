/* Wrapping Paper */

/obj/item/stack/wrapping_paper
	name = "wrapping paper"
	desc = "Wrap packages with this festive paper to make gifts."
	icon = 'icons/obj/stacks/miscellaneous.dmi'
	icon_state = "wrap_paper"
	item_flags = NOBLUDGEON
	amount = 25
	max_amount = 25
	resistance_flags = FLAMMABLE
	merge_type = /obj/item/stack/wrapping_paper

/obj/item/stack/wrapping_paper/use(used, transfer, check = TRUE)
	var/turf/T = get_turf(src)
	. = ..()
	if(QDELETED(src) && !transfer)
		new /obj/item/c_tube(T)


/* Package Wrap */

/obj/item/stack/package_wrap
	name = "package wrapper"
	singular_name = "wrapping sheet"
	desc = "You can use this to wrap items in."
	icon = 'icons/obj/stacks/miscellaneous.dmi'
	icon_state = "deliveryPaper"
	item_flags = NOBLUDGEON
	amount = 25
	max_amount = 25
	resistance_flags = FLAMMABLE
	merge_type = /obj/item/stack/package_wrap

/obj/item/stack/package_wrap/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] begins wrapping [user.p_them()]self in \the [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	if(use(3))
		var/obj/structure/big_delivery/P = new /obj/structure/big_delivery(get_turf(user.loc))
		P.icon_state = "deliverypackage5"
		user.forceMove(P)
		P.add_fingerprint(user)
		return OXYLOSS
	else
		to_chat(user, span_warning("You need more paper!"))
		return SHAME

/obj/item/proc/can_be_package_wrapped() //can the item be wrapped with package wrapper into a delivery package
	if(w_class >= WEIGHT_CLASS_GIGANTIC)
		return FALSE
	return TRUE

/obj/item/storage/can_be_package_wrapped()
	return FALSE

/obj/item/storage/box/can_be_package_wrapped()
	return TRUE

/obj/item/small_delivery/can_be_package_wrapped()
	return FALSE

/obj/item/stack/package_wrap/afterattack(obj/target, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(!istype(target))
		return
	if(target.anchored)
		return

	if(isitem(target))
		var/obj/item/I = target
		if(!I.can_be_package_wrapped())
			return
		if(user.is_holding(I))
			if(!user.dropItemToGround(I))
				return
		else if(!isturf(I.loc))
			return
		if(use(1))
			var/obj/item/small_delivery/P = new /obj/item/small_delivery(get_turf(I.loc))
			if(user.Adjacent(I))
				P.add_fingerprint(user)
				I.add_fingerprint(user)
				user.put_in_hands(P)
			I.forceMove(P)
			var/size = round(I.w_class)
			P.name = "[weight_class_to_text(size)] parcel"
			P.w_class = size
			size = min(size, 5)
			P.icon_state = "deliverypackage[size]"

	else if(istype (target, /obj/structure/closet))
		var/obj/structure/closet/O = target
		if(O.opened)
			return
		if(!O.delivery_icon) //no delivery icon means unwrappable closet (e.g. body bags)
			to_chat(user, span_warning("You can't wrap this!"))
			return
		if(use(3))
			var/obj/structure/big_delivery/P = new /obj/structure/big_delivery(get_turf(O.loc))
			P.icon_state = O.delivery_icon
			P.drag_slowdown = O.drag_slowdown
			O.forceMove(P)
			P.add_fingerprint(user)
			O.add_fingerprint(user)
		else
			to_chat(user, span_warning("You need more paper!"))
			return
	else
		to_chat(user, span_warning("The object you are trying to wrap is unsuitable for the sorting machinery!"))
		return

	user.visible_message(span_notice("[user] wraps [target]."))
	user.log_message("has used [name] on [key_name(target)]", LOG_ATTACK, color="blue")

/obj/item/stack/package_wrap/use(used, transfer = FALSE, check = TRUE)
	var/turf/T = get_turf(src)
	. = ..()
	if(QDELETED(src) && !transfer)
		new /obj/item/c_tube(T)

/obj/item/c_tube
	name = "cardboard tube"
	desc = "A tube... of cardboard."
	icon = 'icons/obj/stacks/miscellaneous.dmi'
	icon_state = "c_tube"
	throwforce = 0
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 5
