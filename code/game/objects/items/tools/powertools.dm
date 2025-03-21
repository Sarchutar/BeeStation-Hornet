/obj/item/powertool
	name = "Power tool"
	desc = "A basic powertool that does nothing."
	icon = 'icons/obj/tools.dmi'
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	custom_materials = list(/datum/material/iron=150,/datum/material/silver=50,/datum/material/titanium=25) //done for balance reasons, making them high value for research, but harder to get
	armor_type = /datum/armor/item_powertool
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	toolspeed = 0.7


/datum/armor/item_powertool
	fire = 50
	acid = 30

/obj/item/powertool/attack_self(mob/user)
	toggle_mode(user)

/obj/item/powertool/proc/toggle_mode(mob/user)
	return

//Hand Drill

/obj/item/powertool/hand_drill
	name = "hand drill"
	desc = "A simple powered hand drill. It's fitted with a screw bit."
	icon_state = "drill_screw"
	item_state = "drill"
	worn_icon_state = "drill"

	force = 8 //might or might not be too high, subject to change
	throwforce = 8
	throw_speed = 2
	throw_range = 3//it's heavier than a screw driver/wrench, so it does more damage, but can't be thrown as far

	hitsound = 'sound/items/drill_hit.ogg'

	tool_behaviour = TOOL_SCREWDRIVER
	usesound = 'sound/items/drill_use.ogg'

/obj/item/powertool/hand_drill/toggle_mode(mob/user)
	playsound(get_turf(user), 'sound/items/change_drill.ogg', 50, 1)
	if(tool_behaviour == TOOL_SCREWDRIVER)
		balloon_alert(user, "You attach the bolt driver bit.")
		become_wrench()
	else
		balloon_alert(user, "You attach the screw driver bit.")
		become_screwdriver()

/obj/item/powertool/hand_drill/proc/become_wrench()
	icon_state = "drill_bolt"
	tool_behaviour = TOOL_WRENCH

	hitsound = null

	attack_verb_continuous = list("attacks", "bashes", "batters", "bludgeons", "whacks")
	attack_verb_simple = list("attack", "bash", "batter", "bludgeon", "whack")
	throw_range = 7

/obj/item/powertool/hand_drill/proc/become_screwdriver()
	icon_state = "drill_screw"
	tool_behaviour = TOOL_SCREWDRIVER

	hitsound = 'sound/items/drill_hit.ogg'

	attack_verb_continuous = list("drills", "screws", "jabs", "whacks")
	attack_verb_simple = list("drill", "screw", "jab", "whack")
	throw_range = 3

/obj/item/powertool/hand_drill/suicide_act(mob/living/user)
	if(tool_behaviour == TOOL_SCREWDRIVER)
		user.visible_message(span_suicide("[user] is putting [src] to [user.p_their()] temple. It looks like [user.p_theyre()] trying to commit suicide!"))
	else
		user.visible_message(span_suicide("[user] is pressing [src] against [user.p_their()] head! It looks like [user.p_theyre()] trying to commit suicide!"))
	return BRUTELOSS

/obj/item/powertool/hand_drill/attack(mob/living/M, mob/living/user)
	if(!istype(M) || tool_behaviour != TOOL_SCREWDRIVER)
		return ..()
	if(!user.is_zone_selected(BODY_ZONE_PRECISE_EYES, precise_only = TRUE) && !user.is_zone_selected(BODY_ZONE_HEAD, simplified_probability = 40))
		return ..()
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("You don't want to harm [M]!"))
		return
	if(HAS_TRAIT(user, TRAIT_CLUMSY) && prob(50))
		M = user
	return eyestab(M,user)

//Jaws of life

/obj/item/powertool/jaws_of_life
	name = "jaws of life"
	desc = "A set of jaws of life, compressed through the magic of science. It's fitted with a prying head."
	usesound = 'sound/items/jaws_pry.ogg'
	icon_state = "jaws_pry"
	item_state = "jawsoflife"
	worn_icon_state = "jawsoflife"

	tool_behaviour = TOOL_CROWBAR

	force = 15
	throwforce = 7
	attack_verb_continuous = list("attacks", "bashes", "batters", "bludgeons", "whacks")
	attack_verb_simple = list("attack", "bash", "batter", "bludgeon", "whack")

/obj/item/powertool/jaws_of_life/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_DOOR_PRYER, TRAIT_JAWS_OF_LIFE)

/obj/item/powertool/jaws_of_life/toggle_mode(mob/user)
	playsound(get_turf(user), 'sound/items/change_jaws.ogg', 50, 1)
	if(tool_behaviour == TOOL_CROWBAR)
		balloon_alert(user, "You attach the cutting jaws.")
		become_wirecutters()
	else
		balloon_alert(user, "You attach the prying jaws.")
		become_crowbar()

/obj/item/powertool/jaws_of_life/proc/become_wirecutters()
	icon_state = "jaws_cutter"
	tool_behaviour = TOOL_WIRECUTTER

	usesound = 'sound/items/jaws_cut.ogg'

	attack_verb_continuous = list("pinches", "nips")
	attack_verb_simple = list("pinch", "nip")
	force = 6
	throw_speed = 3

	REMOVE_TRAIT(src, TRAIT_DOOR_PRYER, TRAIT_JAWS_OF_LIFE)

/obj/item/powertool/jaws_of_life/proc/become_crowbar()
	icon_state = "jaws_pry"
	tool_behaviour = TOOL_CROWBAR

	usesound = 'sound/items/jaws_pry.ogg'

	attack_verb_continuous = list("attacks", "bashes", "batters", "bludgeons", "whacks")
	attack_verb_simple = list("attack", "bash", "batter", "bludgeon", "whack")
	force = 15
	throw_speed = 2

	ADD_TRAIT(src, TRAIT_DOOR_PRYER, TRAIT_JAWS_OF_LIFE)

/obj/item/powertool/jaws_of_life/suicide_act(mob/living/user)
	if(tool_behaviour == TOOL_CROWBAR)
		user.visible_message(span_suicide("[user] is putting [user.p_their()] head in [src], it looks like [user.p_theyre()] trying to commit suicide!"))
		playsound(loc, 'sound/items/jaws_pry.ogg', 50, 1, -1)
	else
		user.visible_message(span_suicide("[user] is wrapping \the [src] around [user.p_their()] neck. It looks like [user.p_theyre()] trying to rip [user.p_their()] head off!"))
		playsound(loc, 'sound/items/jaws_cut.ogg', 50, 1, -1)
		if(iscarbon(user))
			var/mob/living/carbon/C = user
			var/obj/item/bodypart/BP = C.get_bodypart(BODY_ZONE_HEAD)
			if(BP)
				BP.drop_limb()
				playsound(loc,pick('sound/misc/desecration-01.ogg','sound/misc/desecration-02.ogg','sound/misc/desecration-01.ogg') ,50, 1, -1)
	return BRUTELOSS

/obj/item/powertool/jaws_of_life/attack(mob/living/carbon/C, mob/living/user)
	if(tool_behaviour == TOOL_WIRECUTTER && istype(C) && C.handcuffed)
		user.visible_message(span_notice("[user] cuts [C]'s restraints with [src]!"))
		log_combat(user, C, "cut handcuffs from", important = FALSE)
		qdel(C.handcuffed)
		return
	else
		..()
