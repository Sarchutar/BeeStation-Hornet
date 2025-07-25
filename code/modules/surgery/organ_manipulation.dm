/datum/surgery/organ_manipulation
	name = "organ manipulation"
	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD)
	requires_real_bodypart = 1
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/saw,
		/datum/surgery_step/clamp_bleeders,
		/datum/surgery_step/incise,
		/datum/surgery_step/manipulate_organs,
		//there should be bone fixing
		/datum/surgery_step/close
		)

/datum/surgery/organ_manipulation/soft
	possible_locs = list(BODY_ZONE_PRECISE_GROIN, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
	self_operable = TRUE
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/clamp_bleeders,
		/datum/surgery_step/incise,
		/datum/surgery_step/manipulate_organs,
		/datum/surgery_step/close
		)

/datum/surgery/organ_manipulation/alien
	name = "alien organ manipulation"
	possible_locs = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD, BODY_ZONE_PRECISE_GROIN, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
	target_mobtypes = list(/mob/living/carbon/alien/humanoid)
	steps = list(
		/datum/surgery_step/saw,
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/saw,
		/datum/surgery_step/manipulate_organs,
		/datum/surgery_step/close
		)

/datum/surgery/organ_manipulation/mechanic
	name = "prosthesis organ manipulation"
	possible_locs = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD)
	requires_bodypart_type = BODYTYPE_ROBOTIC
	lying_required = FALSE
	self_operable = TRUE
	speed_modifier = 0.8 //on a surgery bed you can do prosthetic manipulation relatively risk-free
	steps = list(
		/datum/surgery_step/mechanic_open,
		/datum/surgery_step/open_hatch,
		/datum/surgery_step/mechanic_unwrench,
		/datum/surgery_step/prepare_electronics,
		/datum/surgery_step/manipulate_organs,
		/datum/surgery_step/mechanic_wrench,
		/datum/surgery_step/mechanic_close
		)

/datum/surgery/organ_manipulation/mechanic/soft
	possible_locs = list(BODY_ZONE_PRECISE_GROIN, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
	steps = list(
		/datum/surgery_step/mechanic_open,
		/datum/surgery_step/open_hatch,
		/datum/surgery_step/prepare_electronics,
		/datum/surgery_step/manipulate_organs,
		/datum/surgery_step/mechanic_close
		)

/datum/surgery_step/manipulate_organs
	time = 64
	name = "manipulate organs"
	repeatable = 1
	implements = list(/obj/item/organ = 100, /obj/item/organ_storage = 100)
	var/implements_extract = list(TOOL_HEMOSTAT = 100, TOOL_CROWBAR = 55)
	var/current_type
	var/obj/item/organ/I = null
	preop_sound = 'sound/surgery/organ2.ogg'
	success_sound = 'sound/surgery/organ1.ogg'

/datum/surgery_step/manipulate_organs/New()
	..()
	implements = implements + implements_extract

/datum/surgery_step/manipulate_organs/preop(mob/user, mob/living/carbon/target, obj/item/tool, datum/surgery/surgery)
	I = null
	if(istype(tool, /obj/item/organ_storage))
		if(!tool.contents.len)
			to_chat(user, span_notice("There is nothing inside [tool]!"))
			return -1
		I = tool.contents[1]
		if(!isorgan(I))
			to_chat(user, span_notice("You cannot put [I] into [target]'s [parse_zone(surgery.location)]!"))
			return -1
		tool = I
	if(isorgan(tool))
		current_type = "insert"
		I = tool
		if(surgery.location != I.zone || target.get_organ_slot(I.slot))
			to_chat(user, span_notice("There is no room for [I] in [target]'s [parse_zone(surgery.location)]!"))
			return -1
		if(istype(I, /obj/item/organ/brain/positron))
			var/obj/item/bodypart/affected = target.get_bodypart(check_zone(I.zone))
			if(!affected)
				return -1
			if(IS_ORGANIC_LIMB(affected))
				to_chat(user, span_notice("You can't put [I] into a meat enclosure!"))
				return -1
			if(!isipc(target))
				to_chat(user, span_notice("[target] does not have the proper connectors to interface with [I]."))
				return -1
		var/obj/item/organ/meatslab = tool
		if(!meatslab.useable)
			to_chat(user, span_warning("[I] seems to have been chewed on, you can't use this!"))
			return -1
		display_results(user, target, span_notice("You begin to insert [tool] into [target]'s [parse_zone(surgery.location)]..."),
			span_notice("[user] begins to insert [tool] into [target]'s [parse_zone(surgery.location)]."),
			span_notice("[user] begins to insert something into [target]'s [parse_zone(surgery.location)]."))
		log_combat(user, target, "tried to insert [I.name] into")

	else if(implement_type in implements_extract)
		current_type = "extract"
		var/list/organs = target.get_organs_for_zone(surgery.location)
		if(!organs.len)
			to_chat(user, span_notice("There are no removable organs in [target]'s [parse_zone(surgery.location)]!"))
			return -1
		else
			for(var/obj/item/organ/O in organs)
				O.on_find(user)
				organs -= O
				organs[O.name] = O

			I = input("Remove which organ?", "Surgery", null, null) as null|anything in sort_list(organs)
			if(I && user && target && user.Adjacent(target) && user.get_active_held_item() == tool)
				I = organs[I]
				if(!I)
					return -1
				display_results(user, target, span_notice("You begin to extract [I] from [target]'s [parse_zone(surgery.location)]..."),
					"[user] begins to extract [I] from [target]'s [parse_zone(surgery.location)].",
					"[user] begins to extract something from [target]'s [parse_zone(surgery.location)].")
				log_combat(user, target, "tried to extract [I.name] from")
			else
				return -1

/datum/surgery_step/manipulate_organs/success(mob/living/user, mob/living/carbon/target, obj/item/tool, datum/surgery/surgery)
	if(current_type == "insert")
		if(istype(tool, /obj/item/organ_storage))
			I = tool.contents[1]
			tool.icon_state = initial(tool.icon_state)
			tool.desc = initial(tool.desc)
			tool.cut_overlays()
			tool = I
		else
			I = tool
		user.temporarilyRemoveItemFromInventory(I, TRUE)
		I.Insert(target)
		display_results(user, target, span_notice("You insert [tool] into [target]'s [parse_zone(surgery.location)]."),
			"[user] inserts [tool] into [target]'s [parse_zone(surgery.location)]!",
			"[user] inserts something into [target]'s [parse_zone(surgery.location)]!")
		log_combat(user, target, "surgically installed [I.name] into")

	else if(current_type == "extract")
		if(I && I.owner == target)
			display_results(user, target, span_notice("You successfully extract [I] from [target]'s [parse_zone(surgery.location)]."),
				"[user] successfully extracts [I] from [target]'s [parse_zone(surgery.location)]!",
				"[user] successfully extracts something from [target]'s [parse_zone(surgery.location)]!")
			log_combat(user, target, "surgically removed [I.name] from")
			I.Remove(target)
			I.forceMove(get_turf(target))
		else
			display_results(user, target, span_notice("You can't extract anything from [target]'s [parse_zone(surgery.location)]!"),
				"[user] can't seem to extract anything from [target]'s [parse_zone(surgery.location)]!",
				"[user] can't seem to extract anything from [target]'s [parse_zone(surgery.location)]!")
	return 0
