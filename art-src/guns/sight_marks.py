# The iron sights of the kitbash guns, as the two marks zee aims down (zee's IronSight.from_marks):
# nodes `sight_rear` (the top of the rear sight) and `sight_front` (the top of the front post), in the
# model's own frame as it ships (Godot axes: x right, y up, z toward the muzzle, origin at the middle
# of the base). With the marks zee builds no ring and no rear block over the model.
#
# The values are read off each gun's centre-line top profile (z, y of the highest vertex in a 3 cm
# bin), at the rear sight and the front end. build.py does not write them: run this after every
# build or texture bake (arena-weapons tex_bake), it adds them to the shipped glbs and is safe to repeat:
#
#   python3 art-src/guns/sight_marks.py            # patch every glb in assets/kitbash/ (idempotent)
import json
import os
import struct
import sys

MARKS = {
    "uzi": ((-0.17, 0.207), (0.08, 0.207)),
    "sawed_off": ((-0.04, 0.133), (0.23, 0.133)),
    "machine_gun": ((-0.06, 0.189), (0.24, 0.189)),
    "grenade_launcher": ((0.09, 0.28), (0.27, 0.28)),
    "rocket_launcher": ((-0.375, 0.186), (0.30, 0.186)),
    "flamethrower": ((-0.23, 0.141), (0.22, 0.141)),
    "silenced_pistol": ((-0.17, 0.146), (0.07, 0.146)),
}


def patch(path, rear, front):
    """Adds the two marks as empty children of the model's root node (moving them when already there)."""
    b = open(path, "rb").read()
    jlen = struct.unpack("<I", b[12:16])[0]
    doc = json.loads(b[20:20 + jlen])
    rest = b[20 + jlen:]
    nodes = doc["nodes"]
    root = doc["scenes"][0]["nodes"][0]
    kids = nodes[root].setdefault("children", [])
    for name, (z, y) in (("sight_rear", rear), ("sight_front", front)):
        have = [i for i in kids if nodes[i].get("name") == name]
        if have:
            nodes[have[0]]["translation"] = [0.0, y, z]
            continue
        nodes.append({"name": name, "translation": [0.0, y, z]})
        kids.append(len(nodes) - 1)
    raw = json.dumps(doc, separators=(",", ":")).encode()
    raw += b" " * (-len(raw) % 4)
    total = 12 + 8 + len(raw) + len(rest)
    open(path, "wb").write(b[:8] + struct.pack("<I", total) + struct.pack("<I", len(raw)) + b[16:20] + raw + rest)


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    kit = os.path.join(here, "..", "..", "assets", "kitbash")
    for gun, (rear, front) in MARKS.items():
        patch(os.path.join(kit, gun + ".glb"), rear, front)
        print("marked", gun)
