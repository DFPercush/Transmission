
local modifiers =
{
[0]="NONE",
	--[]="NAME",
[1]="DEF", -- tank, blu/cannonball
[2]="HP", -- mnk/chi, sword, rdm/convert, yellow HP sets
[3]="HPP",
[4]="CONVMPTOHP", -- melee, yellow HP
[5]="MP", -- death, mages
[6]="MPP",
[7]="CONVHPTOMP", -- mages, yellow, smn

[8]="STR",
[9]="DEX",
[10]="VIT",
[11]="AGI",
[12]="INT",
[13]="MND",
[14]="CHR",

	-- Elemental Defenses
	--[128]="128",
[15]="FIREDEF",
[16]="ICEDEF",
[17]="WINDDEF",
[18]="EARTHDEF",
[19]="THUNDERDEF",
[20]="WATERDEF",
[21]="LIGHTDEF",
[22]="DARKDEF",

[23]="ATT",
[24]="RATT",

[25]="ACC",
[26]="RACC",

[27]="ENMITY",
[427]="ENMITY_LOSS_REDUCTION",

[28]="MATT",
[29]="MDEF",
[30]="MACC",
[31]="MEVA",

	-- Magic Accuracy and Elemental Attacks
[32]="FIREATT",
[33]="ICEATT",
[34]="WINDATT",
[35]="EARTHATT",
[36]="THUNDERATT",
[37]="WATERATT",
[38]="LIGHTATT",
[39]="DARKATT",
[40]="FIREACC",
[41]="ICEACC",
[42]="WINDACC",
[43]="EARTHACC",
[44]="THUNDERACC",
[45]="WATERACC",
[46]="LIGHTACC",
[47]="DARKACC",

[48]="WSACC",

	-- Resistance to damage type
	-- Value is stored as a percentage of damage reduction (to within 1000)
	-- Example:[100]="1000",
[49]="SLASHRES",
[50]="PIERCERES",
[51]="IMPACTRES",
[52]="HTHRES",

	-- Damage Reduction to Elements
	-- Value is stored as a percentage of damage reduction (to within 1000)
	-- Example:[100]="1000",
[54]="FIRERES",
[55]="ICERES",
[56]="WINDRES",
[57]="EARTHRES",
[58]="THUNDERRES",
[59]="WATERRES",
[60]="LIGHTRES",
[61]="DARKRES",

[62]="ATTP",
[63]="DEFP",

[64]="COMBAT_SKILLUP_RATE",
[65]="MAGIC_SKILLUP_RATE",

[66]="RATTP",

[68]="EVA",
[69]="RDEF",
[70]="REVA",
[71]="MPHEAL",
[72]="HPHEAL",
[73]="STORETP",
[486]="TACTICAL_PARRY",
[487]="MAG_BURST_BONUS",
[488]="INHIBIT_TP",

	-- Working Skills (weapon combat skills)
[80]="HTH",
[81]="DAGGER",
[82]="SWORD",
[83]="GSWORD",
[84]="AXE",
[85]="GAXE",
[86]="SCYTHE",
[87]="POLEARM",
[88]="KATANA",
[89]="GKATANA",
[90]="CLUB",
[91]="STAFF",
[101]="AUTO_MELEE_SKILL",
[102]="AUTO_RANGED_SKILL",
[103]="AUTO_MAGIC_SKILL",
[104]="ARCHERY",
[105]="MARKSMAN",
[106]="THROW",
[107]="GUARD",
[108]="EVASION",
[109]="SHIELD",
[110]="PARRY",

	-- Magic Skills
[111]="DIVINE",
[112]="HEALING",
[113]="ENHANCE",
[114]="ENFEEBLE",
[115]="ELEM",
[116]="DARK",
[117]="SUMMONING",
[118]="NINJUTSU",
[119]="SINGING",
[120]="STRING",
[121]="WIND",
[122]="BLUE",

	-- Synthesis Skills
[127]="FISH",
[128]="WOOD",
[129]="SMITH",
[130]="GOLDSMITH",
[131]="CLOTH",
[132]="LEATHER",
[133]="BONE",
[134]="ALCHEMY",
[135]="COOK",
[136]="SYNERGY",
[137]="RIDING",

	-- Chance you will not make an hq synth (Impossibility of HQ synth)
[144]="ANTIHQ_WOOD",
[145]="ANTIHQ_SMITH",
[146]="ANTIHQ_GOLDSMITH",
[147]="ANTIHQ_CLOTH",
[148]="ANTIHQ_LEATHER",
[149]="ANTIHQ_BONE",
[150]="ANTIHQ_ALCHEMY",
[151]="ANTIHQ_COOK",

	-- Damage / Crit Damage / Delay
[160]="DMG",
[161]="DMGPHYS",
[190]="DMGPHYS_II",
[162]="DMGBREATH",
[163]="DMGMAGIC",
[831]="DMGMAGIC_II",
[164]="DMGRANGE",

[387]="UDMGPHYS",
[388]="UDMGBREATH",
[389]="UDMGMAGIC",
[390]="UDMGRANGE",

[165]="CRITHITRATE",
[421]="CRIT_DMG_INCREASE",
[964]="RANGED_CRIT_DMG_INCREASE",
[166]="ENEMYCRITRATE",
[908]="CRIT_DEF_BONUS",
[562]="MAGIC_CRITHITRATE",
[563]="MAGIC_CRIT_DMG_INCREASE",

[903]="FENCER_TP_BONUS",
[904]="FENCER_CRITHITRATE",

[898]="SMITE",
[899]="TACTICAL_GUARD",
[976]="GUARD_PERCENT",

[167]="HASTE_MAGIC",
[383]="HASTE_ABILITY",
[384]="HASTE_GEAR",
[168]="SPELLINTERRUPT",
[169]="MOVE",
[972]="MOUNT_MOVE",
[170]="FASTCAST",
[407]="UFASTCAST",
[519]="CURE_CAST_TIME",
[901]="ELEMENTAL_CELERITY",
[171]="DELAY",
[172]="RANGED_DELAY",
[173]="MARTIAL_ARTS",
[174]="SKILLCHAINBONUS",
[175]="SKILLCHAINDMG",
[978]="MAX_SWINGS",
[979]="ADDITIONAL_SWING_CHANCE",

[311]="MAGIC_DAMAGE",

	-- FOOD!
[176]="FOOD_HPP",
[177]="FOOD_HP_CAP",
[178]="FOOD_MPP",
[179]="FOOD_MP_CAP",
[180]="FOOD_ATTP",
[181]="FOOD_ATT_CAP",
[182]="FOOD_DEFP",
[183]="FOOD_DEF_CAP",
[184]="FOOD_ACCP",
[185]="FOOD_ACC_CAP",
[186]="FOOD_RATTP",
[187]="FOOD_RATT_CAP",
[188]="FOOD_RACCP",
[189]="FOOD_RACC_CAP",
[99]="FOOD_MACCP",
[100]="FOOD_MACC_CAP",
[937]="FOOD_DURATION",

	-- Killer-Effects - (Most by Traits/JobAbility)
[224]="VERMIN_KILLER",
[225]="BIRD_KILLER",
[226]="AMORPH_KILLER",
[227]="LIZARD_KILLER",
[228]="AQUAN_KILLER",
[229]="PLANTOID_KILLER",
[230]="BEAST_KILLER",
[231]="UNDEAD_KILLER",
[232]="ARCANA_KILLER",
[233]="DRAGON_KILLER",
[234]="DEMON_KILLER",
[235]="EMPTY_KILLER",
[236]="HUMANOID_KILLER",
[237]="LUMORIAN_KILLER",
[238]="LUMINION_KILLER",

	-- Resistances to enfeebles - Traits/Job Ability
[240]="SLEEPRES",
[241]="POISONRES",
[242]="PARALYZERES",
[243]="BLINDRES",
[244]="SILENCERES",
[245]="VIRUSRES",
[246]="PETRIFYRES",
[247]="BINDRES",
[248]="CURSERES",
[249]="GRAVITYRES",
[250]="SLOWRES",
[251]="STUNRES",
[252]="CHARMRES",
[253]="AMNESIARES",
[254]="LULLABYRES",
[255]="DEATHRES",
[958]="STATUSRES",

[257]="PARALYZE",
[258]="MIJIN_RERAISE",
[259]="DUAL_WIELD",

	-- Warrior
[288]="DOUBLE_ATTACK",
[483]="WARCRY_DURATION",
[948]="BERSERK_EFFECT",
[954]="BERSERK_DURATION",
[955]="AGGRESSOR_DURATION",
[956]="DEFENDER_DURATION",

	-- Monk
[97]="BOOST_EFFECT",
[123]="CHAKRA_MULT",
[124]="CHAKRA_REMOVAL",
[289]="SUBTLE_BLOW",
[291]="COUNTER",
[292]="KICK_ATTACK_RATE",
[428]="PERFECT_COUNTER_ATT",
[429]="FOOTWORK_ATT_BONUS",
[543]="COUNTERSTANCE_EFFECT",
[552]="DODGE_EFFECT",
[561]="FOCUS_EFFECT",

	-- White Mage
[293]="AFFLATUS_SOLACE",
[294]="AFFLATUS_MISERY",
[484]="AUSPICE_EFFECT",
[524]="AOE_NA",
[838]="REGEN_MULTIPLIER",
[860]="CURE2MP_PERCENT",
[910]="DIVINE_BENISON",

	-- Black Mage
[295]="CLEAR_MIND",
[296]="CONSERVE_MP",

	-- Red Mage
[299]="BLINK",
[300]="STONESKIN",
[301]="PHALANX",
[290]="ENF_MAG_POTENCY",
[297]="ENHANCES_SABOTEUR",

	-- Thief
[93]="FLEE_DURATION",
[298]="STEAL",
[896]="DESPOIL",
[883]="PERFECT_DODGE",
[302]="TRIPLE_ATTACK",
[303]="TREASURE_HUNTER",
[874]="SNEAK_ATK_DEX",
[520]="TRICK_ATK_AGI",
[835]="MUG_EFFECT",
[884]="ACC_COLLAB_EFFECT",
[885]="HIDE_DURATION",
[897]="GILFINDER",

	-- Paladin
[857]="HOLY_CIRCLE_DURATION",
[92]="RAMPART_DURATION",
[426]="ABSORB_PHYSDMG_TO_MP",
[485]="SHIELD_MASTERY_TP",
[837]="SENTINEL_EFFECT",
[905]="SHIELD_DEF_BONUS",
[965]="COVER_TO_MP",
[966]="COVER_MAGIC_AND_RANGED",
[967]="COVER_DURATION",

	-- Dark Knight
[858]="ARCANE_CIRCLE_DURATION",
[96]="SOULEATER_EFFECT",
[906]="DESPERATE_BLOWS",
[907]="STALWART_SOUL",

	-- Beastmaster
[304]="TAME",
[360]="CHARM_TIME",
[364]="REWARD_HP_BONUS",
[391]="CHARM_CHANCE",
[503]="FERAL_HOWL_DURATION",
[564]="JUG_LEVEL_RANGE",

	-- Bard
[433]="MINNE_EFFECT",
[434]="MINUET_EFFECT",
[435]="PAEON_EFFECT",
[436]="REQUIEM_EFFECT",
[437]="THRENODY_EFFECT",
[438]="MADRIGAL_EFFECT",
[439]="MAMBO_EFFECT",
[440]="LULLABY_EFFECT",
[441]="ETUDE_EFFECT",
[442]="BALLAD_EFFECT",
[443]="MARCH_EFFECT",
[444]="FINALE_EFFECT",
[445]="CAROL_EFFECT",
[446]="MAZURKA_EFFECT",
[447]="ELEGY_EFFECT",
[448]="PRELUDE_EFFECT",
[449]="HYMNUS_EFFECT",
[450]="VIRELAI_EFFECT",
[451]="SCHERZO_EFFECT",
[452]="ALL_SONGS_EFFECT",
[453]="MAXIMUM_SONGS_BONUS",
[454]="SONG_DURATION_BONUS",
[455]="SONG_SPELLCASTING_TIME",
[833]="SONG_RECAST_DELAY",

	-- Ranger
[98]="CAMOUFLAGE_DURATION",
[305]="RECYCLE",
[365]="SNAP_SHOT",
[359]="RAPID_SHOT",
[340]="WIDESCAN",
[420]="BARRAGE_ACC",
[422]="DOUBLE_SHOT_RATE",
[423]="VELOCITY_SNAPSHOT_BONUS",
[424]="VELOCITY_RATT_BONUS",
[425]="SHADOW_BIND_EXT",
[312]="SCAVENGE_EFFECT",
[314]="SHARPSHOT",

	-- Samurai
[95]="WARDING_CIRCLE_DURATION",
[94]="MEDITATE_DURATION",
[306]="ZANSHIN",
[508]="THIRD_EYE_COUNTER_RATE",
[839]="THIRD_EYE_ANTICIPATE_RATE",

	-- Ninja
[307]="UTSUSEMI",
[900]="UTSUSEMI_BONUS",
[308]="NINJA_TOOL",
[522]="NIN_NUKE_BONUS",
[911]="DAKEN",

	-- Dragoon
[859]="ANCIENT_CIRCLE_DURATION",
[361]="JUMP_TP_BONUS",
[362]="JUMP_ATT_BONUS",
[363]="HIGH_JUMP_ENMITY_REDUCTION",
[828]="FORCE_JUMP_CRIT",
[829]="WYVERN_EFFECTIVE_BREATH",
[974]="WYVERN_SUBJOB_TRAITS",

	-- Summoner
[371]="AVATAR_PERPETUATION",
[372]="WEATHER_REDUCTION",
[373]="DAY_REDUCTION",
[346]="PERPETUATION_REDUCTION",
[357]="BP_DELAY",
[540]="ENHANCES_ELEMENTAL_SIPHON",
[541]="BP_DELAY_II",
[126]="BP_DAMAGE",
[913]="BLOOD_BOON",

	-- Blue Mage
[309]="BLUE_POINTS",
[945]="BLUE_LEARN_CHANCE",

	-- Corsair
[382]="EXP_BONUS",
[528]="ROLL_RANGE",
[542]="JOB_BONUS_CHANCE",

[316]="DMG_REFLECT",
[317]="ROLL_ROGUES",
[318]="ROLL_GALLANTS",
[319]="ROLL_CHAOS",
[320]="ROLL_BEAST",
[321]="ROLL_CHORAL",
[322]="ROLL_HUNTERS",
[323]="ROLL_SAMURAI",
[324]="ROLL_NINJA",
[325]="ROLL_DRACHEN",
[326]="ROLL_EVOKERS",
[327]="ROLL_MAGUS",
[328]="ROLL_CORSAIRS",
[329]="ROLL_PUPPET",
[330]="ROLL_DANCERS",
[331]="ROLL_SCHOLARS",
[869]="ROLL_BOLTERS",
[870]="ROLL_CASTERS",
[871]="ROLL_COURSERS",
[872]="ROLL_BLITZERS",
[873]="ROLL_TACTICIANS",
[874]="ROLL_ALLIES",
[875]="ROLL_MISERS",
[876]="ROLL_COMPANIONS",
[877]="ROLL_AVENGERS",
[878]="ROLL_NATURALISTS",
[879]="ROLL_RUNEISTS",
[332]="BUST",
[411]="QUICK_DRAW_DMG",
[834]="QUICK_DRAW_DMG_PERCENT",
[191]="QUICK_DRAW_MACC",
[881]="PHANTOM_ROLL",
[882]="PHANTOM_DURATION",

	-- Puppetmaster
[504]="MANEUVER_BONUS",
[505]="OVERLOAD_THRESH",
[842]="AUTO_DECISION_DELAY",
[843]="AUTO_SHIELD_BASH_DELAY",
[844]="AUTO_MAGIC_DELAY",
[845]="AUTO_HEALING_DELAY",
[846]="AUTO_HEALING_THRESHOLD",
[847]="BURDEN_DECAY",
[848]="AUTO_SHIELD_BASH_SLOW",
[849]="AUTO_TP_EFFICIENCY",
[850]="AUTO_SCAN_RESISTS",
[853]="REPAIR_EFFECT",
[854]="REPAIR_POTENCY",
[855]="PREVENT_OVERLOAD",
[125]="SUPPRESS_OVERLOAD",
[938]="AUTO_STEAM_JACKET",
[939]="AUTO_STEAM_JACKED_REDUCTION",
[940]="AUTO_SCHURZEN",
[941]="AUTO_EQUALIZER",
[942]="AUTO_PERFORMANCE_BOOST",
[943]="AUTO_ANALYZER",

	-- Dancer
[333]="FINISHING_MOVES",
[490]="SAMBA_DURATION",
[491]="WALTZ_POTENTCY",
[492]="JIG_DURATION",
[493]="VFLOURISH_MACC",
[494]="STEP_FINISH",
[403]="STEP_ACCURACY",
[497]="WALTZ_DELAY",
[498]="SAMBA_PDURATION",
[836]="REVERSE_FLOURISH_EFFECT",

	-- Scholar
[393]="BLACK_MAGIC_COST",
[394]="WHITE_MAGIC_COST",
[395]="BLACK_MAGIC_CAST",
[396]="WHITE_MAGIC_CAST",
[397]="BLACK_MAGIC_RECAST",
[398]="WHITE_MAGIC_RECAST",
[399]="ALACRITY_CELERITY_EFFECT",
[334]="LIGHT_ARTS_EFFECT",
[335]="DARK_ARTS_EFFECT",
[336]="LIGHT_ARTS_SKILL",
[337]="DARK_ARTS_SKILL",
[338]="LIGHT_ARTS_REGEN",
[339]="REGEN_DURATION",
[478]="HELIX_EFFECT",
[477]="HELIX_DURATION",
[400]="STORMSURGE_EFFECT",
[401]="SUBLIMATION_BONUS",
[489]="GRIMOIRE_SPELLCASTING",

	-- Geo
[959]="CARDINAL_CHANT",
[960]="INDI_DURATION",
[961]="GEOMANCY",
[962]="WIDENED_COMPASS",
[968]="MENDING_HALATION",
[969]="RADIAL_ARCANA",
[970]="CURATIVE_RECANTATION",
[971]="PRIMEVAL_ZEAL",

[341]="ENSPELL",
[343]="ENSPELL_DMG",
[432]="ENSPELL_DMG_BONUS",
[856]="ENSPELL_CHANCE",
[342]="SPIKES",
[344]="SPIKES_DMG",

[345]="TP_BONUS",
[880]="SAVETP",
[944]="CONSERVE_TP",

	-- Rune Fencer

[963]="INQUARTATA",

	-- Stores the amount of elemental affinity (elemental staves mostly) - damage, acc, and perpetuation is all handled separately
[347]="FIRE_AFFINITY_DMG",
[348]="ICE_AFFINITY_DMG",
[349]="WIND_AFFINITY_DMG",
[350]="EARTH_AFFINITY_DMG",
[351]="THUNDER_AFFINITY_DMG",
[352]="WATER_AFFINITY_DMG",
[353]="LIGHT_AFFINITY_DMG",
[354]="DARK_AFFINITY_DMG",

[544]="FIRE_AFFINITY_ACC",
[545]="ICE_AFFINITY_ACC",
[546]="WIND_AFFINITY_ACC",
[547]="EARTH_AFFINITY_ACC",
[548]="THUNDER_AFFINITY_ACC",
[549]="WATER_AFFINITY_ACC",
[550]="LIGHT_AFFINITY_ACC",
[551]="DARK_AFFINITY_ACC",

[553]="FIRE_AFFINITY_PERP",
[554]="ICE_AFFINITY_PERP",
[555]="WIND_AFFINITY_PERP",
[556]="EARTH_AFFINITY_PERP",
[557]="THUNDER_AFFINITY_PERP",
[558]="WATER_AFFINITY_PERP",
[559]="LIGHT_AFFINITY_PERP",
[560]="DARK_AFFINITY_PERP",

	-- Special Modifier+
[355]="ADDS_WEAPONSKILL",
[356]="ADDS_WEAPONSKILL_DYN",

[358]="STEALTH",
[946]="SNEAK_DURATION",
[947]="INVISIBLE_DURATION",

[366]="MAIN_DMG_RATING",
[367]="SUB_DMG_RATING",
[368]="REGAIN",
[406]="REGAIN_DOWN",
[369]="REFRESH",
[405]="REFRESH_DOWN",
[370]="REGEN",
[404]="REGEN_DOWN",
[374]="CURE_POTENCY",
[260]="CURE_POTENCY_II",
[375]="CURE_POTENCY_RCVD",
[376]="RANGED_DMG_RATING",
[377]="MAIN_DMG_RANK",
[378]="SUB_DMG_RANK",
[379]="RANGED_DMG_RANK",
[380]="DELAYP",
[381]="RANGED_DELAYP",

[385]="SHIELD_BASH",
[386]="KICK_DMG",
[392]="WEAPON_BASH",

[402]="WYVERN_BREATH",

	-- Gear set modifiers
[408]="DA_DOUBLE_DAMAGE",
[409]="TA_TRIPLE_DAMAGE",
[410]="ZANSHIN_DOUBLE_DAMAGE",
[479]="RAPID_SHOT_DOUBLE_DAMAGE",
[480]="ABSORB_DMG_CHANCE",
[481]="EXTRA_DUAL_WIELD_ATTACK",
[482]="EXTRA_KICK_ATTACK",
[415]="SAMBA_DOUBLE_DAMAGE",
[416]="NULL_PHYSICAL_DAMAGE",
[417]="QUICK_DRAW_TRIPLE_DAMAGE",
[418]="BAR_ELEMENT_NULL_CHANCE",
[419]="GRIMOIRE_INSTANT_CAST",
[430]="QUAD_ATTACK",

	-- Reraise (Auto Reraise, used by gear)
[456]="RERAISE_I",
[457]="RERAISE_II",
[458]="RERAISE_III",

	-- Elemental Absorb Chance
[459]="FIRE_ABSORB",
[460]="ICE_ABSORB",
[461]="WIND_ABSORB",
[462]="EARTH_ABSORB",
[463]="LTNG_ABSORB",
[464]="WATER_ABSORB",
[465]="LIGHT_ABSORB",
[466]="DARK_ABSORB",

	-- Elemental Null Chance
[467]="FIRE_NULL",
[468]="ICE_NULL",
[469]="WIND_NULL",
[470]="EARTH_NULL",
[471]="LTNG_NULL",
[472]="WATER_NULL",
[473]="LIGHT_NULL",
[474]="DARK_NULL",

[475]="MAGIC_ABSORB",
[476]="MAGIC_NULL",
[512]="PHYS_ABSORB",
[516]="ABSORB_DMG_TO_MP",

[431]="ADDITIONAL_EFFECT",
[499]="ITEM_SPIKES_TYPE",
[500]="ITEM_SPIKES_DMG",
[501]="ITEM_SPIKES_CHANCE",
	--[431]="ITEM_ADDEFFECT_TYPE",
	--[499]="ITEM_SUBEFFECT",
	--[500]="ITEM_ADDEFFECT_DMG",
	--[501]="ITEM_ADDEFFECT_CHANCE",
	--[950]="ITEM_ADDEFFECT_ELEMENT",
	--[951]="ITEM_ADDEFFECT_STATUS",
	--[952]="ITEM_ADDEFFECT_POWER",
	--[953]="ITEM_ADDEFFECT_DURATION",

[496]="GOV_CLEARS",

[256]="AFTERMATH",

[506]="EXTRA_DMG_CHANCE",
[507]="OCC_DO_EXTRA_DMG",

[863]="REM_OCC_DO_DOUBLE_DMG",
[864]="REM_OCC_DO_TRIPLE_DMG",

[867]="REM_OCC_DO_DOUBLE_DMG_RANGED",
[868]="REM_OCC_DO_TRIPLE_DMG_RANGED",

[865]="MYTHIC_OCC_ATT_TWICE",
[866]="MYTHIC_OCC_ATT_THRICE",

[412]="EAT_RAW_FISH",
[413]="EAT_RAW_MEAT",


[67]="ENHANCES_CURSNA_RCVD",
[310]="ENHANCES_CURSNA",
[495]="ENHANCES_HOLYWATER",

[414]="RETALIATION",

[509]="CLAMMING_IMPROVED_RESULTS",
[510]="CLAMMING_REDUCED_INCIDENTS",

[511]="CHOCOBO_RIDING_TIME",

[513]="HARVESTING_RESULT",
[514]="LOGGING_RESULT",
[515]="MINING_RESULT",

[517]="EGGHELM",

[518]="SHIELDBLOCKRATE",
[313]="DIA_DOT",
[315]="ENH_DRAIN_ASPIR",
[521]="AUGMENTS_ABSORB",
[523]="AMMO_SWING",
[826]="AMMO_SWING_TYPE",
[525]="AUGMENTS_CONVERT",
[526]="AUGMENTS_SA",
[527]="AUGMENTS_TA",
[873]="AUGMENTS_FEINT",
[886]="AUGMENTS_ASSASSINS_CHARGE",
[887]="AUGMENTS_AMBUSH",
[889]="AUGMENTS_AURA_STEAL",
[912]="AUGMENTS_CONSPIRATOR",
[529]="ENHANCES_REFRESH",
[530]="NO_SPELL_MP_DEPLETION",
[531]="FORCE_FIRE_DWBONUS",
[532]="FORCE_ICE_DWBONUS",
[533]="FORCE_WIND_DWBONUS",
[534]="FORCE_EARTH_DWBONUS",
[535]="FORCE_LIGHTNING_DWBONUS",
[536]="FORCE_WATER_DWBONUS",
[537]="FORCE_LIGHT_DWBONUS",
[538]="FORCE_DARK_DWBONUS",
[539]="STONESKIN_BONUS_HP",
[565]="DAY_NUKE_BONUS",
[566]="IRIDESCENCE",
[567]="BARSPELL_AMOUNT",
[827]="BARSPELL_MDEF_BONUS",
[568]="RAPTURE_AMOUNT",
[569]="EBULLIENCE_AMOUNT",
[832]="AQUAVEIL_COUNT",
[890]="ENH_MAGIC_DURATION",
[891]="ENHANCES_COURSERS_ROLL",
[892]="ENHANCES_CASTERS_ROLL",
[893]="ENHANCES_BLITZERS_ROLL",
[894]="ENHANCES_ALLIES_ROLL",
[895]="ENHANCES_TACTICIANS_ROLL",
[902]="OCCULT_ACUMEN",

[909]="QUICK_MAGIC",

	-- Crafting food effects
[851]="SYNTH_SUCCESS",
[852]="SYNTH_SKILL_GAIN",
[861]="SYNTH_FAIL_RATE",
[862]="SYNTH_HQ_RATE",
[916]="DESYNTH_SUCCESS",
[917]="SYNTH_FAIL_RATE_FIRE",
[918]="SYNTH_FAIL_RATE_ICE",
[919]="SYNTH_FAIL_RATE_WIND",
[920]="SYNTH_FAIL_RATE_EARTH",
[921]="SYNTH_FAIL_RATE_LIGHTNING",
[922]="SYNTH_FAIL_RATE_WATER",
[923]="SYNTH_FAIL_RATE_LIGHT",
[924]="SYNTH_FAIL_RATE_DARK",
[925]="SYNTH_FAIL_RATE_WOOD",
[926]="SYNTH_FAIL_RATE_SMITH",
[927]="SYNTH_FAIL_RATE_GOLDSMITH",
[928]="SYNTH_FAIL_RATE_CLOTH",
[929]="SYNTH_FAIL_RATE_LEATHER",
[930]="SYNTH_FAIL_RATE_BONE",
[931]="SYNTH_FAIL_RATE_ALCHEMY",
[932]="SYNTH_FAIL_RATE_COOK",

	-- Weaponskill %damage modifiers
	-- The following modifier should not ever be set, but %damage modifiers to weaponskills use the next 255 IDs (this modifier + the WSID)
	-- For example, +10% damage to Chant du Cygne would be ID 570 + 225 (795)
[570]="WEAPONSKILL_DAMAGE_BASE",

[840]="ALL_WSDMG_ALL_HITS",
	-- Per https:--www.bg-wiki.com/bg/Weapon_Skill_Damage we need all 3..
[841]="ALL_WSDMG_FIRST_HIT",
[949]="WS_NO_DEPLETE",
[980]="WS_STR_BONUS",
[957]="WS_DEX_BONUS",
[981]="WS_VIT_BONUS",
[982]="WS_AGI_BONUS",
[983]="WS_INT_BONUS",
[984]="WS_MND_BONUS",
[985]="WS_CHR_BONUS",

[914]="EXPERIENCE_RETAINED",
[915]="CAPACITY_BONUS",
[933]="CONQUEST_BONUS",
[934]="CONQUEST_REGION_BONUS",
[935]="CAMPAIGN_BONUS",

[973]="SUBTLE_BLOW_II",
[975]="GARDENING_WILT_BONUS",

	-- The spares take care of finding the next ID to use so long as we don't forget to list IDs that have been freed up by refactoring.
	-- 570 through 825 used by WS DMG mods these are not spares.
	--[986]="SPARE",
	--[987]="SPARE",
	--[988]="SPARE",
}

return modifiers
