extends SceneTree

## Prints, per kitbash gun, where its bore is at the muzzle end: the median height and side of
## the vertices in the last 3 cm along +Z, with the model's front z. Zee measures the muzzle at
## the model's origin height (the middle of the base), so `muzzle_offset` is (x, y, 0) from here.
##   godot --headless --path . --script tools/bore.gd

func _initialize() -> void:
	for file in DirAccess.get_files_at("res://assets/kitbash/"):
		if not file.ends_with(".glb"):
			continue
		var node: Node = (load("res://assets/kitbash/" + file) as PackedScene).instantiate()
		var pts := PackedVector3Array()
		_collect(node, Transform3D.IDENTITY, pts)
		var zmax := -INF
		for p in pts:
			zmax = maxf(zmax, p.z)
		var ys: Array = []
		var xs: Array = []
		for p in pts:
			if p.z > zmax - 0.03:
				ys.append(p.y)
				xs.append(p.x)
		ys.sort()
		xs.sort()
		print("%-20s zmax %.3f  front y min %.3f med %.3f max %.3f  x med %.3f" % [file, zmax, ys[0], ys[ys.size() / 2], ys[-1], xs[xs.size() / 2]])
		node.free()
	quit()


func _collect(node: Node, parent: Transform3D, into: PackedVector3Array) -> void:
	var xf := parent
	if node is Node3D:
		xf = parent * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mesh := (node as MeshInstance3D).mesh
		for s in range(mesh.get_surface_count()):
			for v in mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
				into.append(xf * v)
	for c in node.get_children():
		_collect(c, xf, into)
