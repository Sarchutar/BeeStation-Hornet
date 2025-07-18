/datum/round_event_control/spider_infestation
	name = "Spider Infestation"
	typepath = /datum/round_event/ghost_role/spider_infestation
	weight = 10
	min_players = 20
	dynamic_should_hijack = TRUE
	can_malf_fake_alert = TRUE

/datum/round_event/ghost_role/spider_infestation
	role_name = ROLE_SPIDER
	announceWhen = 400
	fakeable = TRUE
	minimum_required = 1
	var/spawncount = 2
	var/fed = 1

/datum/round_event/ghost_role/spider_infestation/setup()
	announceWhen = rand(announceWhen, announceWhen + 50)

/datum/round_event/ghost_role/spider_infestation/announce(fake)
	priority_announce("Unidentified lifesigns detected coming aboard [station_name()]. Secure any exterior access, including ducting and ventilation.", "Lifesign Alert", ANNOUNCER_ALIENS)

/datum/round_event/ghost_role/spider_infestation/spawn_role()
	var/list/vents = list()
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/temp_vent in GLOB.machines)
		if(QDELETED(temp_vent))
			continue
		if(is_station_level(temp_vent.loc.z) && !temp_vent.welded)
			var/datum/pipenet/temp_vent_parent = temp_vent.parents[1]
			if(!temp_vent_parent)
				continue// no parent vent

			if(length(temp_vent_parent.other_atmos_machines) > 20)
				vents += temp_vent // Makes sure the vent network's big enough

	if(!length(vents))
		return MAP_ERROR

	var/list/mob/dead/observer/candidates = SSpolling.poll_ghost_candidates(
		role = /datum/role_preference/midround_ghost/spider,
		check_jobban = ROLE_SPIDER,
		poll_time = 30 SECONDS,
		role_name_text = "spider broodmother",
		alert_pic = /mob/living/simple_animal/hostile/poison/giant_spider/broodmother,
	)
	if(!length(candidates))
		return NOT_ENOUGH_PLAYERS

	var/datum/team/spiders/spider_team = new()
	spider_team.directive = "Ensure the survival of your brood and overtake whatever structure you find yourself in."
	while(spawncount > 0 && length(vents) && length(candidates))
		var/obj/vent = pick_n_take(vents)
		var/client/C = pick_n_take(candidates)

		var/mob/living/simple_animal/hostile/poison/giant_spider/broodmother/spooder = new(vent.loc)
		spooder.key = C.key
		var/datum/antagonist/spider/spider_antag = spooder.mind.has_antag_datum(/datum/antagonist/spider)
		spider_antag.set_spider_team(spider_team)
		if(fed)
			spooder.fed += 3 // Give our spiders some friends to help them get started
			spooder.lay_eggs.update_buttons()
			fed--
		spawncount--
		message_admins("[ADMIN_LOOKUPFLW(spooder)] has been made into a spider by an event.")
		log_game("[key_name(spooder)] was spawned as a spider by an event.")
		spawned_mobs += spooder

	return SUCCESSFUL_SPAWN
