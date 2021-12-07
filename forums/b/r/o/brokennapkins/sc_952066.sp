/*
 * Basic Server Crontab (run specific tasks at times / days of the week) - www.sourcemod.net
 *
 * Plugin licensed under the GPLv3
 *
 * Coded by dubbeh - www.yegods.net
 *
 */

#pragma semicolon 1
#define REQUIRE_PLUGIN
#include <sourcemod>
#undef REQUIRE_PLUGIN

/*
 * INCLUDE SOURCE FOR SCRONTAB.INC TO COMPILE
 */

#if defined _sc_module_included
 #endinput
#endif
#define _sc_module_included

public SharedPlugin:__pl_sc_module =
{
    name = "sc_module",
    file = "sc_module.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

// Maximum size a cron job can be
#define MAX_JOB_LEN		255

// Wildcard "?" to skip checking the weekday/hour/minute
#define JOB_WILDCARD	0x3F

/*
 * Add a new cron job
 *
 * @param 	iWeekDayStart = The weekday the job starts (0-6)
 * @param 	iWeekDayEnd = The weekday the job ends (0-6) 
 * @param 	iHourStart = The hour the job starts (0-23)
 * @param 	iHourEnd = The hour the job ends (0-23) 
 * @param 	iMinuteStart = The minute the job starts (0-59)
 * @param 	iMinuteEnd = The minute the job ends (0-59) 
 * @param	szCronJob = The job to be run
 * @return	Cron job ID (Watch out because this can change over time. With adding & removing jobs)
 *
 */

native SC_AddCronJob (iWeekdayStart = -1, iWeekdayEnd = -1, iHourStart = -1, iHourEnd = -1, iMinuteStart = -1, iMinuteEnd = -1, const String:szCronJob[] = "");


/*
 * Find the index for a specific cron job
 *  
 * This is important when using arrays & removing jobs to grab the current index
 *
 * @param 	iWeekDayStart = The weekday the job starts (0-6)
 * @param 	iWeekDayEnd = The weekday the job ends (0-6) 
 * @param 	iHourStart = The hour the job starts (0-23)
 * @param 	iHourEnd = The hour the job ends (0-23) 
 * @param 	iMinuteStart = The minute the job starts (0-59)
 * @param 	iMinuteEnd = The minute the job ends (0-59) 
 * @param	szCronJob = The job to be run
 * @return	The cron job Id
 *
 */

native SC_SearchCronJobId (iWeekdayStart = -1, iWeekdayEnd = -1, iHourStart = -1, iHourEnd = -1, iMinuteStart = -1, iMinuteEnd = -1, const String:szCronJob[] = "");


/*
 * Remove a cron job
 *
 * @param 	iCronId = The cron job id to remove
 * @return	true if the job was removed sucessfully
 *
 */

native bool:SC_RemoveCronJob (iCronId = -1);


/*
 * Called just before the cron job is run
 * 
 * Allows a cron job to be skipped
 *  
 * @param   iCronId = The cron job ID 
 * @param	szCronJob = The job to be run
 * @return	Plugin_Handled to skip the cron job or Plugin_Continue to run it
 */

forward Action:SC_OnCronCall (iCronId, const String:szCronJob[]);


/*
 * Get the current number of cron jobs
 *
 * @return The number of current cron jobs
 *
 */

native SC_GetNumberOfCronJobs ();


/*
 * Get the cron job for the current id
 *
 * @param 	iCronId = The cron job id to retrieve
 * @param 	iWeekDayStart = The weekday the job starts (0-6)
 * @param 	iWeekDayEnd = The weekday the job ends (0-6) 
 * @param 	iHourStart = The hour the job starts (0-23)
 * @param 	iHourEnd = The hour the job ends (0-23) 
 * @param 	iMinuteStart = The minute the job starts (0-59)
 * @param 	iMinuteEnd = The minute the job ends (0-59) 
 * @param 	szCronJob = Place to store the cron job task
 * @return 	true if the job id was found or false if the job id is out of range
 *
 */

native bool:SC_GetCronJobFromId (iCronId = -1, &iWeekdayStart, &iWeekdayEnd, &iHourStart, &iHourEnd, &iMinuteStart, &iMinuteEnd, const String:szCronJob[]);


/*
 * Remove all the current cron jobs 
 */
native SC_RemoveAllCronJobs ();


/*
 * Check the weekday is in range
 */  
stock bool:SC_IsWeekdayValid (iWeekday)
{
    if ((iWeekday > 6) && (iWeekday != JOB_WILDCARD))
        return false;
    return true;
}


/*
 * Check the hour is in range
 */
stock bool:SC_IsHourValid (iHour)
{
    if ((iHour > 23)  && (iHour != JOB_WILDCARD))
        return false;
    return true;
}


/*
 * Check the minute is in range
 */  
stock bool:SC_IsMinuteValid (iMinute)
{
    if ((iMinute > 59) && (iMinute != JOB_WILDCARD))
        return false;
    return true;
}

/* END INCLUDE */



#define PLUGIN_VERSION 	"1.0.1.0"

public Plugin:myinfo =
{
    name = "Server Crontab",
    author = "dubbeh",
    description = "Run specific server commands tasks at certain times",
    version = PLUGIN_VERSION,
    url = "http://www.yegods.net/"
};

static const String:g_szConfigFile[] = "sourcemod/sc_jobs.cfg";


public OnPluginStart ()
{
    /* Create the version console variable */
    CreateConVar ("sc_version", PLUGIN_VERSION, "Server Crontab version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);

    /* Register all the admin commands */
    RegAdminCmd ("sc_addjob", Command_AddCronJob, ADMFLAG_ROOT, "sc_addjob weekday_start weekday_end hour_start hour_end minute_start minute_end \"cronjob\" - Adds a new cronjob");
    RegAdminCmd ("sc_removejob", Command_RemoveCronJob, ADMFLAG_ROOT, "sc_removejob cronjob_id - Removes a job using cronjob_id");
    RegAdminCmd ("sc_removealljobs", Command_RemoveAllCronJobs, ADMFLAG_ROOT, "sc_removealljobs - Removes all crontab jobs");
    RegAdminCmd ("sc_printjobs", Command_PrintCronJobs, ADMFLAG_ROOT, "sc_printjobs - Prints out all the current cron jobs in the console");
    
    /* Create the de`conneclayed config execute timer */
    CreateTimer (10.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed (Handle:timer)
{
    /* Run delayed startup timer. Thanks to FlyingMongoose/sslice for the idea :) */
    /* We want to execute the jobs config file here */
    ServerCommand ("exec %s", g_szConfigFile);
}

public Action:Command_AddCronJob (client, args)
{
    decl String:szTempBuffer[MAX_JOB_LEN] = "";
    static iJobWeekdayStart = 0, iJobWeekdayEnd = 0, iJobHourStart = 0, iJobHourEnd = 0, iJobMinuteStart = 0, iJobMinuteEnd = 0;

    if (args == 7)
    {
        GetCmdArg (1, szTempBuffer, sizeof (szTempBuffer));
        iJobWeekdayStart = CronStringToInt (szTempBuffer);
        GetCmdArg (2, szTempBuffer, sizeof (szTempBuffer));
        iJobWeekdayEnd = CronStringToInt (szTempBuffer);
        if (SC_IsWeekdayValid (iJobWeekdayStart) && SC_IsWeekdayValid (iJobWeekdayEnd))
        {
            GetCmdArg (3, szTempBuffer, sizeof (szTempBuffer));
            iJobHourStart = CronStringToInt (szTempBuffer);
            GetCmdArg (4, szTempBuffer, sizeof (szTempBuffer));
            iJobHourEnd = CronStringToInt (szTempBuffer);
            if (SC_IsHourValid (iJobHourStart) && SC_IsHourValid (iJobHourEnd))
            {
                GetCmdArg (5, szTempBuffer, sizeof (szTempBuffer));
                iJobMinuteStart = CronStringToInt (szTempBuffer);
                GetCmdArg (6, szTempBuffer, sizeof (szTempBuffer));
                iJobMinuteEnd = CronStringToInt (szTempBuffer);
                if (SC_IsMinuteValid (iJobMinuteStart) && SC_IsMinuteValid (iJobMinuteEnd))
                {
                    GetCmdArg (7, szTempBuffer, sizeof (szTempBuffer));
                    if ((SC_AddCronJob (iJobWeekdayStart, iJobWeekdayEnd, iJobHourStart, iJobHourEnd, iJobMinuteStart, iJobMinuteEnd, szTempBuffer)) != -1)
                        ReplyToCommand (client, "[SC] Cron job \"%s\" added successfully", szTempBuffer);
				}
				else
				{
					ReplyToCommand (client, "[SC] Add job error - Minute value is invalid");
				}
			}
			else
			{
                ReplyToCommand (client, "[SC] Add job error - Hour value is invalid");
			}
		}
		else
		{
			ReplyToCommand (client, "[SC] Add job error - Weekday value is invalid");
		}
    }
    else
    {
        ReplyToCommand (client, "[SC] sc_addjob - Invalid usage");
        ReplyToCommand (client, "[SC] Usage: sc_addjob weekday hour minute \"cronjob\"");
    }

    return Plugin_Handled;
}

public Action:Command_RemoveCronJob (client, args)
{
    decl String:szTempBuffer[8] = "";

    if (args == 1)
    {
        GetCmdArg (1, szTempBuffer, sizeof (szTempBuffer));
        new iJobId = StringToInt (szTempBuffer);

        if (iJobId <= SC_GetNumberOfCronJobs ())
        {
            SC_RemoveCronJob (iJobId);
            ReplyToCommand (client, "[SC] Removed cron job %d successfully", iJobId);
        }
        else
        {
            ReplyToCommand (client, "[SC] Invalid Cronjob Id");
        }
    }
    else
    {
        ReplyToCommand (client, "[SC] sc_removejob - Invalid usage");
        ReplyToCommand (client, "[SC] Usage: sc_removejob cronjob_id");
    }

    return Plugin_Handled;
}

public Action:Command_RemoveAllCronJobs (client, args)
{
    SC_RemoveAllCronJobs ();
    ReplyToCommand (client, "[SC] All cron jobs removed");
    return Plugin_Handled;
}

public Action:Command_PrintCronJobs (client, args)
{
    new iNumOfJobs, iJobWeekdayStart, iJobWeekdayEnd, iJobHourStart, iJobHourEnd, iJobMinuteStart, iJobMinuteEnd;
    decl String:szCronJob[MAX_JOB_LEN], String:szJobWeekdayStart[8],
	     String:szJobWeekdayEnd[8], String:szJobHourStart[8], String:szJobHourEnd[8],
		 String:szJobMinuteStart[8], String:szJobMinuteEnd[8];

    ReplyToCommand (client, "Id\tWeekdayStart\tWeekdayEnd\tHourStart\tHourEnd\tMinuteStart\tMinuteEnd\tJob");
    iNumOfJobs = SC_GetNumberOfCronJobs ();
    for (new i = 0; i <= iNumOfJobs; i++)
    {
        SC_GetCronJobFromId (i, iJobWeekdayStart, iJobWeekdayEnd, iJobHourStart, iJobHourEnd, iJobMinuteStart, iJobMinuteEnd, szCronJob);
        CronIntToString (iJobWeekdayStart, szJobWeekdayStart, sizeof (szJobWeekdayStart));
        CronIntToString (iJobWeekdayEnd, szJobWeekdayEnd, sizeof (szJobWeekdayEnd));
        CronIntToString (iJobHourStart, szJobHourStart, sizeof (szJobHourStart));
        CronIntToString (iJobHourEnd, szJobHourEnd, sizeof (szJobHourEnd));
        CronIntToString (iJobMinuteStart, szJobMinuteStart, sizeof (szJobMinuteStart));
        CronIntToString (iJobMinuteEnd, szJobMinuteEnd, sizeof (szJobMinuteEnd));
        ReplyToCommand (client, "%d\t%s\t\t%s\t%s\t\t%s\t%s\t\t%s\t\t%s", i, szJobWeekdayStart, szJobWeekdayEnd, szJobHourStart, szJobHourEnd, szJobMinuteStart, szJobMinuteEnd, szCronJob);
    }

    return Plugin_Handled;
}


stock CronStringToInt (String:szStr[])
{
    if (szStr[0] == '?')
        return JOB_WILDCARD;
    return StringToInt (szStr);
}

stock CronIntToString (iNum, String:szOutBuffer[], iOutBufferSize)
{
    if (iNum == JOB_WILDCARD)
    {
        szOutBuffer[0] = JOB_WILDCARD;
        szOutBuffer[1] = 0;
    }
    else
    {
        IntToString (iNum, szOutBuffer, iOutBufferSize);
    }
}

