/datum/surgery/healing
	steps = list(/datum/surgery_step/incise,
				/datum/surgery_step/heal,
				/datum/surgery_step/close)

	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_CHEST)
	requires_bodypart_type = FALSE
	replaced_by = /datum/surgery
	ignore_clothes = TRUE
	var/healing_step_type
	var/antispam = FALSE

/datum/surgery/healing/New(surgery_target, surgery_location, surgery_bodypart)
	..()
	if(healing_step_type)
		steps = list(/datum/surgery_step/incise/nobleed,
					healing_step_type, //hehe cheeky
					/datum/surgery_step/close/nofail)

/datum/surgery_step/heal
	name = "repair body"
	implements = list(TOOL_HEMOSTAT = 100, TOOL_SCREWDRIVER = 65, /obj/item/pen = 55)
	repeatable = TRUE
	time = 2 SECONDS
	success_sound = 'sound/surgery/retractor2.ogg'
	failure_sound = 'sound/surgery/organ2.ogg'
	fuckup_damage = 0
	var/brutehealing = 0
	var/burnhealing = 0
	var/missinghpbonus = 0 //heals an extra point of damager per X missing damage of type (burn damage for burn healing, brute for brute). Smaller Number = More Healing!

/datum/surgery_step/heal/proc/get_progress(mob/user, mob/living/carbon/target, brute_healed, burn_healed)
	return

/datum/surgery_step/heal/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/woundtype
	if(brutehealing && burnhealing)
		woundtype = "wounds"
	else if(brutehealing)
		woundtype = "bruises"
	else //why are you trying to 0,0...?
		woundtype = "burns"
	if(istype(surgery,/datum/surgery/healing))
		var/datum/surgery/healing/the_surgery = surgery
		if(!the_surgery.antispam)
			display_results(user, target, span_notice("You attempt to patch some of [target]'s [woundtype]."),
		span_notice("[user] attempts to patch some of [target]'s [woundtype]."),
		span_notice("[user] attempts to patch some of [target]'s [woundtype]."))

/datum/surgery_step/heal/initiate(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, try_to_fail = FALSE)
	var/list/list_org_limbs = target.get_damaged_bodyparts(brutehealing, burnhealing, FALSE, BODYPART_ORGANIC)
	if(!list_org_limbs.len)
		to_chat(user, span_notice("[target] has no wounds left to treat. The rest of the damage is mechanical limbs"))
	if(..())
		while((brutehealing && target.getBruteLoss()) || (burnhealing && target.getFireLoss()))
			list_org_limbs = target.get_damaged_bodyparts(brutehealing, burnhealing, FALSE, BODYPART_ORGANIC)
			if(!list_org_limbs.len) // if there are no organic bodypart with damage we should stop
				to_chat(user, span_notice("[target] has no wounds left to treat. The rest of the damage is mechanical limbs"))
				break
			if(!..())
				break

/datum/surgery_step/heal/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/umsg = "You succeed in fixing some of [target]'s wounds" //no period, add initial space to "addons"
	var/tmsg = "[user] fixes some of [target]'s wounds" //see above
	var/urhealedamt_brute = brutehealing
	var/urhealedamt_burn = burnhealing
	if(missinghpbonus)
		if(target.stat != DEAD)
			urhealedamt_brute += brutehealing ? round((target.getBruteLoss()/ missinghpbonus),0.1) : 0
			urhealedamt_burn += burnhealing ? round((target.getFireLoss()/ missinghpbonus),0.1) : 0
		else //less healing bonus for the dead since they're expected to have lots of damage to begin with (to make TW into defib not TOO simple)
			urhealedamt_brute += brutehealing ? round((target.getBruteLoss()/ (missinghpbonus*3)),0.1) : 0
			urhealedamt_burn += burnhealing ? round((target.getFireLoss()/ (missinghpbonus*3)),0.1) : 0
	if(!get_location_accessible(target, target_zone))
		urhealedamt_brute *= 0.55
		urhealedamt_burn *= 0.55
		umsg += " as best as you can while they have clothing on"
		tmsg += " as best as they can while [target] has clothing on"
	target.heal_bodypart_damage(urhealedamt_brute,urhealedamt_burn)
	umsg += get_progress(user, target, urhealedamt_brute, urhealedamt_burn)

	display_results(user, target, span_notice("[umsg]."),
		"[tmsg].",
		"[tmsg].")
	if(istype(surgery, /datum/surgery/healing))
		var/datum/surgery/healing/the_surgery = surgery
		the_surgery.antispam = TRUE
	return TRUE

/datum/surgery_step/heal/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_warning("You screwed up!"),
		span_warning("[user] screws up!"),
		span_notice("[user] fixes some of [target]'s wounds."), TRUE)
	var/urdamageamt_burn = brutehealing * 0.8
	var/urdamageamt_brute = burnhealing * 0.8
	if(missinghpbonus)
		urdamageamt_brute += round((target.getBruteLoss()/ (missinghpbonus*2)),0.1)
		urdamageamt_burn += round((target.getFireLoss()/ (missinghpbonus*2)),0.1)

	target.take_bodypart_damage(urdamageamt_brute, urdamageamt_burn, wound_bonus=CANT_WOUND)
	return FALSE

/***************************BRUTE***************************/
/datum/surgery/healing/brute
	name = "Tend Wounds (Bruises)"

/datum/surgery/healing/brute/basic
	name = "Tend Wounds (Bruises, Basic)"
	replaced_by = /datum/surgery/healing/brute/upgraded
	healing_step_type = /datum/surgery_step/heal/brute/basic
	desc = "A surgical procedure that provides basic treatment for a patient's brute traumas. Heals slightly more when the patient is severely injured."

/datum/surgery/healing/brute/upgraded
	name = "Tend Wounds (Bruises, Adv.)"
	replaced_by = /datum/surgery/healing/brute/upgraded/femto
	requires_tech = TRUE
	healing_step_type = /datum/surgery_step/heal/brute/upgraded
	desc = "A surgical procedure that provides advanced treatment for a patient's brute traumas. Heals more when the patient is severely injured."

/datum/surgery/healing/brute/upgraded/femto
	name = "Tend Wounds (Bruises, Exp.)"
	replaced_by = /datum/surgery/healing/combo/upgraded/femto
	requires_tech = TRUE
	healing_step_type = /datum/surgery_step/heal/brute/upgraded/femto
	desc = "A surgical procedure that provides experimental treatment for a patient's brute traumas. Heals considerably more when the patient is severely injured."

/********************BRUTE STEPS********************/
/datum/surgery_step/heal/brute/get_progress(mob/user, mob/living/carbon/target, brute_healed, burn_healed)
	if(!brute_healed)
		return

	var/estimated_remaining_steps = target.getBruteLoss() / brute_healed
	var/progress_text
	if(locate(/obj/item/healthanalyzer) in user.held_items)
		progress_text = ". Remaining brute: <font color='#ff3333'>[target.getBruteLoss()]</font>"
	else
		switch(estimated_remaining_steps)
			if(-INFINITY to 1)
				return
			if(1 to 3)
				progress_text = ", stitching up the last few scrapes"
			if(3 to 6)
				progress_text = ", counting down the last few bruises left to treat"
			if(6 to 9)
				progress_text = ", continuing to plug away at [target.p_their()] extensive rupturing"
			if(9 to 12)
				progress_text = ", steadying yourself for the long surgery ahead"
			if(12 to 15)
				progress_text = ", though [target.p_they()] still look[target.p_s()] more like ground beef than a person"
			if(15 to INFINITY)
				progress_text = ", though you feel like you're barely making a dent in treating [target.p_their()] pulped body"

	return progress_text

/datum/surgery_step/heal/brute/basic
	name = "tend bruises"
	brutehealing = 5
	missinghpbonus = 15

/datum/surgery_step/heal/brute/upgraded
	brutehealing = 7.5
	missinghpbonus = 10

/datum/surgery_step/heal/brute/upgraded/femto
	brutehealing = 10
	missinghpbonus = 5

/***************************BURN***************************/
/datum/surgery/healing/burn
	name = "Tend Wounds (Burn)"

/datum/surgery/healing/burn/basic
	name = "Tend Wounds (Burn, Basic)"
	replaced_by = /datum/surgery/healing/burn/upgraded
	healing_step_type = /datum/surgery_step/heal/burn/basic
	desc = "A surgical procedure that provides basic treatment for a patient's burns. Heals slightly more when the patient is severely injured."

/datum/surgery/healing/burn/upgraded
	name = "Tend Wounds (Burn, Adv.)"
	replaced_by = /datum/surgery/healing/burn/upgraded/femto
	requires_tech = TRUE
	healing_step_type = /datum/surgery_step/heal/burn/upgraded
	desc = "A surgical procedure that provides advanced treatment for a patient's burns. Heals more when the patient is severely injured."

/datum/surgery/healing/burn/upgraded/femto
	name = "Tend Wounds (Burn, Exp.)"
	replaced_by = /datum/surgery/healing/combo/upgraded/femto
	requires_tech = TRUE
	healing_step_type = /datum/surgery_step/heal/burn/upgraded/femto
	desc = "A surgical procedure that provides experimental treatment for a patient's burns. Heals considerably more when the patient is severely injured."

/********************BURN STEPS********************/
/datum/surgery_step/heal/burn/get_progress(mob/user, mob/living/carbon/target, brute_healed, burn_healed)
	if(!burn_healed)
		return

	var/estimated_remaining_steps = target.getFireLoss() / burn_healed
	var/progress_text
	if(locate(/obj/item/healthanalyzer) in user.held_items)
		progress_text = ". Remaining burn: <font color='#ff9933'>[target.getFireLoss()]</font>"
	else
		switch(estimated_remaining_steps)
			if(-INFINITY to 1)
				return
			if(1 to 3)
				progress_text = ", finishing up the last few singe marks"
			if(3 to 6)
				progress_text = ", counting down the last few blisters left to treat"
			if(6 to 9)
				progress_text = ", continuing to plug away at [target.p_their()] thorough roasting"
			if(9 to 12)
				progress_text = ", steadying yourself for the long surgery ahead"
			if(12 to 15)
				progress_text = ", though [target.p_they()] still look[target.p_s()] more like burnt steak than a person"
			if(15 to INFINITY)
				progress_text = ", though you feel like you're barely making a dent in treating [target.p_their()] charred body"

	return progress_text

/datum/surgery_step/heal/burn/basic
	name = "tend burn wounds"
	burnhealing = 5
	missinghpbonus = 15

/datum/surgery_step/heal/burn/upgraded
	burnhealing = 7.5
	missinghpbonus = 10

/datum/surgery_step/heal/burn/upgraded/femto
	burnhealing = 10
	missinghpbonus = 5

/***************************COMBO***************************/

/datum/surgery/healing/combo
	name = "Tend Wounds (Mixture, Basic)"
	replaced_by = /datum/surgery/healing/combo/upgraded
	requires_tech = TRUE
	healing_step_type = /datum/surgery_step/heal/combo
	desc = "A surgical procedure that provides basic treatment for a patient's burns and brute traumas. Heals slightly more when the patient is severely injured."

/datum/surgery/healing/combo/upgraded
	name = "Tend Wounds (Mixture, Adv.)"
	replaced_by = /datum/surgery/healing/combo/upgraded/femto
	healing_step_type = /datum/surgery_step/heal/combo/upgraded
	desc = "A surgical procedure that provides advanced treatment for a patient's burns and brute traumas. Heals more when the patient is severely injured."


/datum/surgery/healing/combo/upgraded/femto //no real reason to type it like this except consistency, don't worry you're not missing anything
	name = "Tend Wounds (Mixture, Exp.)"
	replaced_by = null
	healing_step_type = /datum/surgery_step/heal/combo/upgraded/femto
	desc = "A surgical procedure that provides experimental treatment for a patient's burns and brute traumas. Heals considerably more when the patient is severely injured."

/********************COMBO STEPS********************/
/datum/surgery_step/heal/combo/get_progress(mob/user, mob/living/carbon/target, brute_healed, burn_healed)
	var/estimated_remaining_steps = 0
	if(brute_healed > 0)
		estimated_remaining_steps = max(0, (target.getBruteLoss() / brute_healed))
	if(burn_healed > 0)
		estimated_remaining_steps = max(estimated_remaining_steps, (target.getFireLoss() / burn_healed)) // whichever is higher between brute or burn steps

	var/progress_text

	if(locate(/obj/item/healthanalyzer) in user.held_items)
		if(target.getBruteLoss())
			progress_text = ". Remaining brute: <font color='#ff3333'>[target.getBruteLoss()]</font>"
		if(target.getFireLoss())
			progress_text += ". Remaining burn: <font color='#ff9933'>[target.getFireLoss()]</font>"
	else
		switch(estimated_remaining_steps)
			if(-INFINITY to 1)
				return
			if(1 to 3)
				progress_text = ", finishing up the last few signs of damage"
			if(3 to 6)
				progress_text = ", counting down the last few patches of trauma"
			if(6 to 9)
				progress_text = ", continuing to plug away at [target.p_their()] extensive injuries"
			if(9 to 12)
				progress_text = ", steadying yourself for the long surgery ahead"
			if(12 to 15)
				progress_text = ", though [target.p_they()] still look[target.p_s()] more like smooshed baby food than a person"
			if(15 to INFINITY)
				progress_text = ", though you feel like you're barely making a dent in treating [target.p_their()] broken body"

	return progress_text

/datum/surgery_step/heal/combo
	name = "tend physical wounds"
	brutehealing = 3
	burnhealing = 3
	missinghpbonus = 15
	time = 1 SECONDS

/datum/surgery_step/heal/combo/upgraded
	brutehealing = 3
	burnhealing = 3
	missinghpbonus = 10

/datum/surgery_step/heal/combo/upgraded/femto
	brutehealing = 1
	burnhealing = 1
	missinghpbonus = 2.5

/datum/surgery_step/heal/combo/upgraded/femto/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_warning("You screwed up!"),
		span_warning("[user] screws up!"),
		span_notice("[user] fixes some of [target]'s wounds."), TRUE)
	target.take_bodypart_damage(5,5)
