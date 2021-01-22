Conf = 
{
	-- How often to notify of progress if it's a short job
	SHORT_TERM_PROGRESS_REPORT_INTERVAL_SECONDS = 5,

	-- How often to notify of progress if it starts taking a long time
	LONG_TERM_PROGRESS_REPORT_INTERVAL_MINUTES = 10,

	-- How long is a long time
	LONG_MODE_START_TIME_SECONDS = 22,

	-- Controls how gear combinations are iterated.
	-- The batch size should be small enough to be processed in a single frame.
	-- The delay should ideally match 1/framerate, maybe a bit less, but not zero or it will freeze.
	-- For release, go as fast as possible while still being responsive
	PERMUTE_BATCH_SIZE = 500,  -- Unit: gear sets/combinations
	PERMUTE_BATCH_DELAY = 0.1, -- Unit: seconds
	
	CLEAR_CACHE_COMMAND_CONFIRMATION_TIMEOUT_SECONDS = 60,  -- //tm cc
	
	--VERBOSITY_LEVEL = 1,

	-- Which status messages will be displayed during the build process.
	-- must be true or false, do not use 1 or 0
	showmsg = 
	{
		ESTIMATED_PERMUTATIONS = false,
		FOUND_SETS = false,
		PROGRESS = true,
		REBUILD_START = true,
		REBUILD_FINISH = true,
		CACHE_LOADED = true,
		CACHE_SAVE_START = true,
		CACHE_SAVED_SUCCESS = true,


		DEBUG_REBUILD_JOB_PURPOSE = false,
		DEBUG_REBUILD_JOB_FINISH = true,
	}
}
