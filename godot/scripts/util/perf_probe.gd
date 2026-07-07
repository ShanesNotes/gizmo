class_name PerfProbe
extends RefCounted

## Samples Engine FPS, scene-tree node count, and orphan count over N frames and
## prints a one-line report. Intended for future perf ceremonies / CI probes.

static func sample_over_frames(tree: SceneTree, frames: int = 60) -> Dictionary:
	var frame_count := maxi(frames, 1)
	var fps_total := 0.0
	var fps_min := INF
	var node_total := 0.0
	var orphan_total := 0.0
	for _i in frame_count:
		await tree.process_frame
		var fps := Engine.get_frames_per_second()
		var nodes := float(_count_tree_nodes(tree.root))
		var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
		fps_total += fps
		fps_min = minf(fps_min, fps)
		node_total += nodes
		orphan_total += orphans
	var report := {
		"frames": frame_count,
		"fps_avg": fps_total / float(frame_count),
		"fps_min": fps_min if fps_min < INF else 0.0,
		"nodes_avg": node_total / float(frame_count),
		"orphans_avg": orphan_total / float(frame_count),
	}
	var line := _format_line(report)
	print(line)
	report["line"] = line
	return report

static func _count_tree_nodes(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _count_tree_nodes(child)
	return count

static func _format_line(report: Dictionary) -> String:
	return (
		"perf_probe frames=%d fps_avg=%.1f fps_min=%.1f nodes_avg=%.0f orphans_avg=%.1f"
		% [
			int(report.get("frames", 0)),
			float(report.get("fps_avg", 0.0)),
			float(report.get("fps_min", 0.0)),
			float(report.get("nodes_avg", 0.0)),
			float(report.get("orphans_avg", 0.0)),
		]
	)