/datum/component/complexsignal/outermost_movable
	var/list/atom/movable/loc_chain
	var/track_movable_moved = FALSE

/datum/component/complexsignal/outermost_movable/proc/get_outermost_movable()
	RETURN_TYPE(/atom/movable)
	return loc_chain[length(loc_chain)]

/datum/component/complexsignal/outermost_movable/proc/on_loc_change(atom/movable/thing, atom/previous_loc)
	var/atom/movable/old_outermost = src.get_outermost_movable()
	var/turf/old_turf = get_turf(previous_loc)
	var/old_z = isnull(old_turf) ? 0 : old_turf.z

	var/atom/movable/loc_crawl = parent
	var/break_index = 0
	var/current_index = 1
	for(var/atom/movable/AM as anything in loc_chain)
		if(!break_index && loc_crawl != AM)
			break_index = current_index
		if(break_index) // chain broken
			src.UnregisterSignal(AM, COMSIG_MOVABLE_SET_LOC)
			if (src.track_movable_moved)
				src.UnregisterSignal(AM, COMSIG_MOVABLE_MOVED)
		if(!break_index)
			loc_crawl = loc_crawl.loc
		current_index++

	if(break_index)
		loc_chain.len = break_index - 1 // cut away the incorrect locs

	loc_crawl = loc_chain[length(loc_chain)].loc
	while(ismovable(loc_crawl))
		loc_chain += loc_crawl
		src.RegisterSignal(loc_crawl, COMSIG_MOVABLE_SET_LOC, .proc/on_loc_change)
		if (src.track_movable_moved)
			src.RegisterSignal(loc_crawl, COMSIG_MOVABLE_MOVED, .proc/on_loc_change)
		loc_crawl = loc_crawl.loc

	var/atom/movable/new_outermost = src.get_outermost_movable()
	var/turf/new_turf = get_turf(parent)
	var/new_z = isnull(new_turf) ? 0 : new_turf.z

	if(new_outermost != old_outermost)
		SEND_COMPLEX_SIGNAL(src, XSIG_OUTERMOST_MOVABLE_CHANGED, old_outermost, new_outermost)
	if (new_turf != old_turf)
		SEND_COMPLEX_SIGNAL(src, XSIG_MOVABLE_TURF_CHANGED, old_turf, new_turf)
	if(new_z != old_z)
		SEND_COMPLEX_SIGNAL(src, XSIG_MOVABLE_Z_CHANGED, old_z, new_z)

/datum/component/complexsignal/outermost_movable/Initialize()
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	src.RegisterSignal(parent, COMSIG_MOVABLE_SET_LOC, .proc/on_loc_change)
	src.loc_chain = list(parent)
	src.on_loc_change()
	. = ..()

/datum/component/complexsignal/outermost_movable/UnregisterFromParent()
	for(var/atom/movable/AM as anything in loc_chain)
		src.UnregisterSignal(AM, COMSIG_MOVABLE_SET_LOC)
		src.UnregisterSignal(AM, COMSIG_MOVABLE_MOVED)
	src.loc_chain.len = 0
	. = ..()

/datum/component/complexsignal/outermost_movable/_register(datum/listener, sig_type, proctype, override = FALSE, ...)
	. = ..()
	if (sig_type == XSIG_MOVABLE_TURF_CHANGED[2])
		var/atom/A = src.get_outermost_movable()
		if(!(A.event_handler_flags & MOVE_NOCLIP))
			src.RegisterSignal(A, COMSIG_MOVABLE_MOVED, .proc/on_loc_change)

		track_movable_moved = TRUE

/datum/component/complexsignal/outermost_movable/_unregister(datum/listener, sig_type)
	. = ..()
	if (sig_type == XSIG_MOVABLE_TURF_CHANGED[2])
		src.UnregisterSignal(src.get_outermost_movable(), COMSIG_MOVABLE_MOVED)
		track_movable_moved = FALSE
