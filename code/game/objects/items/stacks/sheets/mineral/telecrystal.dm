/obj/item/stack/sheet/telecrystal
	name = "telecrystal"
	desc = "It seems to be pulsing with suspiciously enticing energies."
	singular_name = "telecrystal"
	icon = 'icons/obj/stacks/minerals.dmi'
	icon_state = "telecrystal"
	w_class = WEIGHT_CLASS_TINY
	max_amount = 50
	item_flags = NOBLUDGEON | ISWEAPON
	merge_type = /obj/item/stack/sheet/telecrystal

/obj/item/stack/sheet/telecrystal/attack(mob/target, mob/user)
	if(target == user) //You can't go around smacking people with crystals to find out if they have an uplink or not.
		for(var/obj/item/implant/uplink/I in target)
			if(I?.imp_in)
				var/datum/component/uplink/hidden_uplink = I.GetComponent(/datum/component/uplink)
				if(hidden_uplink)
					hidden_uplink.telecrystals += amount
					use(amount)
					to_chat(user, span_notice("You press [src] onto yourself and charge your hidden uplink."))
	else
		return ..()

/obj/item/stack/sheet/telecrystal/afterattack(obj/item/I, mob/user, proximity)
	. = ..()
	if(istype(I, /obj/item/computer_hardware/hard_drive/role/virus/frame))
		var/obj/item/computer_hardware/hard_drive/role/virus/frame/cart = I
		if(!cart.charges)
			to_chat(user, span_notice("[cart] is out of charges, it's refusing to accept [src]."))
			return
		cart.telecrystals += amount
		use(amount)
		to_chat(user, span_notice("You slot [src] into [cart].  The next time it's used, it will also give telecrystals."))

STACKSIZE_MACRO(/obj/item/stack/sheet/telecrystal)
