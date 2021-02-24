
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

storage_ids = 
{
	[0] = "inventory",
	[1] = "safe",
	[2] = "storage",
	--[3] = ??? Maybe delivery box?
	[4] = "locker",
	[5] = "satchel",
	[6] = "sack",
	[7] = "case",
	[8] = "wardrobe",
	[9] = "safe2",
	[10] = "wardrobe2",
	[11] = "wardrobe3",
	[12] = "wardrobe4",
}

}

for k,v in pairs(ret.storage_ids) do ret.storage_ids[v] = k end


local slots = {
    [0] = {id=0,en="Main"},
    [1] = {id=1,en="Sub"},
    [2] = {id=2,en="Range"},
    [3] = {id=3,en="Ammo"},
    [4] = {id=4,en="Head"},
    [5] = {id=5,en="Body"},
    [6] = {id=6,en="Hands"},
    [7] = {id=7,en="Legs"},
    [8] = {id=8,en="Feet"},
    [9] = {id=9,en="Neck"},
    [10] = {id=10,en="Waist"},
    [11] = {id=11,en="Left Ear"},
    [12] = {id=12,en="Right Ear"},
    [13] = {id=13,en="Left Ring"},
    [14] = {id=14,en="Right Ring"},
    [15] = {id=15,en="Back"},
}
ret.slot_index = {}
for k,v in pairs(slots) do
	ret.slot_index[v.id] = v.en
	ret.slot_index[v.en] = v.id
end

return ret
