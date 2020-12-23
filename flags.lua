
local ret = {
job_flags =
{
	WAR = 2,
	MNK = 4,
	WHM = 8,
	BLM = 16,
	RDM = 32,
	THF = 64,
	PLD = 128,
	DRK = 256,
	BST = 512,
	BRD = 1024,
	RNG = 2048,
	SAM = 4096,
	NIN = 8192,
	DRG = 16384,
	SMN = 32768,
	BLU = 65536,
	COR = 131072,
	PUP = 262144,
	DNC = 524288,
	SCH = 1048576,
	GEO = 2097152,
	RUN = 4194304,
},

job_index =
{
	WAR = 1,
	MNK = 2,
	WHM = 3,
	BLM = 4,
	RDM = 5,
	THF = 6,
	PLD = 7,
	DRK = 8,
	BST = 9,
	BRD = 10,
	RNG = 11,
	SAM = 12,
	NIN = 13,
	DRG = 14,
	SMN = 15,
	BLU = 16,
	COR = 17,
	PUP = 18,
	DNC = 19,
	SCH = 20,
	GEO = 21,
	RUN = 22,
},
slot_flags =
{
	main = 1,
	sub = 2,
	range = 4,
	ammo = 8,
	head = 16,
	body = 32,
	hands = 64,
	legs = 128,
	feet = 256,
	neck = 512,
	waist = 1024,
	ear1 = 2048,
	ear2 = 4096,
	ring1 = 8192,
	ring2 = 16384,
	back = 32768,
},
}

ret.slot_index = {}
for k,v in pairs(resources.slots) do
	ret.slot_index[v.id] = v.en
	ret.slot_index[v.en] = v.id
end

return ret
