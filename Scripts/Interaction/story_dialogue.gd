class_name StoryDialogue
extends RefCounted

## The shared "which dialogue does this hotspot play right now" rule.
##
## Both prototype_npc.gd (an NPC you click) and dialogue_hotspot.gd (a tent, a
## door, any Area2D you click) offer one dialogue slot per Global.StoryStage.
## The picking rule lives here once, so a tent and an NPC can never end up
## disagreeing about what "stage 2" means.
##
## The rule: play the slot for the current story stage. If that slot is empty,
## walk *backwards* to the newest earlier slot that is filled. That way a
## hotspot with a single dialogue keeps working unchanged, and a hotspot with
## nothing new to say repeats its old line instead of going silent.

## Index of the slot that should play, or -1 when every slot is empty.
## "slots" is ordered by Global.StoryStage: [first_visit, after_ship, glyphs].
static func stage_to_play(slots: Array[DialogueResource]) -> int:
	# mini() guards against a story stage that has more values than this hotspot
	# has slots, which would otherwise index past the end of the array.
	var stage := mini(int(Global.get_story_stage()), slots.size() - 1)
	while stage >= 0:
		if slots[stage] != null:
			return stage
		stage -= 1
	return -1


## Show the balloon for whichever slot wins, and report which stage that was.
## Returns -1 without opening anything when the hotspot has no dialogue at all.
##
## The caller is the one that awaits DialogueManager.dialogue_ended, because
## only the caller knows what should happen afterwards.
static func play(slots: Array[DialogueResource], titles: Array[String], hotspot_name: String) -> int:
	var stage := stage_to_play(slots)
	if stage < 0:
		push_warning("'%s' was clicked but has no Dialogue Resource assigned." % hotspot_name)
		return -1
	DialogueManager.show_dialogue_balloon(slots[stage], title_for(titles, stage))
	return stage


## The title to jump to for a stage. An empty field means "start" rather than a
## broken jump into the file.
static func title_for(titles: Array[String], stage: int) -> String:
	if stage < 0 or stage >= titles.size():
		return "start"
	var title: String = titles[stage].strip_edges()
	return title if not title.is_empty() else "start"
