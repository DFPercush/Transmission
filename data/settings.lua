Conf = 
{
	-- TODO: LOCALE = "en"

	-- When building sets, scan all storages, not just currently equippable inventory/wardrobe.
	SEARCH_ALL_STORAGES = true,
	
	-- How often to notify of build progress if it's a short job
	SHORT_TERM_PROGRESS_REPORT_INTERVAL_SECONDS = 5,

	-- How often to notify of progress if it starts taking a long time
	LONG_TERM_PROGRESS_REPORT_INTERVAL_MINUTES = 10,

	-- How long is a long time
	LONG_MODE_START_TIME_SECONDS = 322,

	-- Controls how gear combinations are iterated.
	-- The batch size should be small enough to be processed in a single frame.
	-- The delay should ideally match 1/framerate, maybe a bit less, but not zero or it will freeze.
	-- For release, go as fast as possible while still being responsive
	PERMUTE_BATCH_SIZE = 100,  -- Unit: gear sets/combinations
	PERMUTE_BATCH_DELAY = .01, -- Unit: seconds
	
	CLEAR_CACHE_COMMAND_CONFIRMATION_TIMEOUT_SECONDS = 60,  -- //tm cc

	WHERE_TO_DUMP_UNUSED_ITEMS_PRIORITY =
	{
		"slip",
		"safe",
		"safe2",
		"storage",
		"case",
		"satchel",
		"sack",
	},

	LOADOUT_MANUAL_TRANSFER_TIMEOUT = 600,  -- How long (seconds) to wait for the user to manually get/put an item from storage before aborting.
	LOADOUT_DELAY_JITTER_MIN = 0.1,
	LOADOUT_DELAY_JITTER_MAX = 1.0,
	
	-- Which status messages will be displayed during the build process.
	-- must be true or false, do not use 1 or 0
	showmsg = 
	{
		ESTIMATED_PERMUTATIONS = true, --false,
		FOUND_SETS = true,
		PROGRESS = true,
		REBUILD_START = true,
		REBUILD_FINISH = true,
		CACHE_LOADED = true,
		CACHE_SAVE_START = true,
		CACHE_SAVED_SUCCESS = true,

		LOADOUT_WARNING_NO_JOB_DATA = true,

		AVERAGE_DAMAGE_ACCURACY = false,

		DEBUG_REBUILD_JOB_PURPOSE = false,
		DEBUG_REBUILD_JOB_FINISH = true,
	}
}
