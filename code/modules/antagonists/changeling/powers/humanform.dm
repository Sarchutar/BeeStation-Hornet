/datum/action/changeling/humanform
	name = "Human Form"
	desc = "We change into a human. Costs 10 chemicals."
	button_icon_state = "human_form"
	chemical_cost = 10
	req_dna = 1

//Transform into a human.
/datum/action/changeling/humanform/sting_action(mob/living/carbon/user)
	var/datum/antagonist/changeling/changeling = user.mind.has_antag_datum(/datum/antagonist/changeling)
	var/list/names = list()
	for(var/datum/changelingprofile/prof in changeling.stored_profiles)
		names += "[prof.name]"

	var/chosen_name = input("Select the target DNA: ", "Target DNA", null) as null|anything in sort_list(names)
	if(!chosen_name)
		return

	var/datum/changelingprofile/chosen_prof = changeling.get_dna(chosen_name)
	if(!chosen_prof)
		return
	if(!user || user.notransform)
		return 0
	to_chat(user, span_notice("We transform our appearance."))
	..()
	changeling.purchasedpowers -= src

	var/newmob = user.humanize(TR_KEEPITEMS | TR_KEEPIMPLANTS | TR_KEEPORGANS | TR_KEEPDAMAGE | TR_KEEPVIRUS | TR_KEEPSE)

	changeling.transform(newmob, chosen_prof)
	return TRUE
