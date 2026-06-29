/*
 * Basic Server Crontab Main Module(run specific tasks at times / days of the week) - www.sourcemod.net
 *
 * Plugin licensed under the GPLv3
 *
 * Coded by dubbeh - www.yegods.net
 *
 */


#include <sourcemod>

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


#pragma semicolon 			1

#define PLUGIN_VERSION 		"1.0.1.0"

#define JOB_WEEKDAY_START	0
#define JOB_WEEKDAY_END		1
#define JOB_HOUR_START		2
#define JOB_HOUR_END		3
#define JOB_MINUTE_START	4
#define JOB_MINUTE_END		5
#define JOB_TIME_SIZE		6


new Handle:g_hJobsTimeArray = INVALID_HANDLE;
new Handle:g_hJobsTaskArray = INVALID_HANDLE;
new Handle:g_hJobsTimer = INVALID_HANDLE;
new Handle:g_hCronCallForward = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "Server Crontab Module",
    author = "dubbeh",
    description = "Run specific server jobs at certain times in SourceMod",
    version = PLUGIN_VERSION,
    url = "http://www.yegods.net/"
};


public OnPluginStart ()
{
    CreateConVar ("sc_module_version", PLUGIN_VERSION, "Server Crontab Module version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);

    if (((g_hJobsTaskArray = CreateArray (MAX_JOB_LEN, 0)) != INVALID_HANDLE) && ((g_hJobsTimeArray = CreateArray (JOB_TIME_SIZE, 0)) != INVALID_HANDLE))
    {
        g_hCronCallForward = CreateGlobalForward ("OnCronCall", ET_Event, Param_Cell, Param_String);
        g_hJobsTimer = CreateTimer (60.0, CrontabTimer, _, TIMER_REPEAT);
    }
    else
    {
        SetFailState ("SC Module Error - Unable to create the arrays");
    }
}

public OnPluginEnd ()
{
    if (g_hJobsTimer != INVALID_HANDLE)
    {
        KillTimer (g_hJobsTimer);
        CloseHandle (g_hJobsTimer);
        g_hJobsTimer = INVALID_HANDLE;
    }
    if (g_hJobsTimeArray != INVALID_HANDLE)
    {
        ClearArray (g_hJobsTimeArray);
        CloseHandle (g_hJobsTimeArray);
        g_hJobsTimeArray = INVALID_HANDLE;
    }
    if (g_hJobsTaskArray != INVALID_HANDLE)
    {
        ClearArray (g_hJobsTaskArray);
        CloseHandle (g_hJobsTaskArray);
        g_hJobsTaskArray = INVALID_HANDLE;
    }
    if (g_hCronCallForward != INVALID_HANDLE)
    {
        CloseHandle (g_hCronCallForward);
        g_hCronCallForward = INVALID_HANDLE;
    }
}

public bool:AskPluginLoad (Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative ("SC_AddCronJob", Native_AddCronJob);
    CreateNative ("SC_RemoveCronJob", Native_RemoveCronJob);
    CreateNative ("SC_SearchCronJobId", Native_SearchCronJobId);
    CreateNative ("SC_GetNumberOfCronJobs", Native_GetNumberOfCronJobs);
    CreateNative ("SC_GetCronJobFromId", Native_GetCronJobFromId);
    CreateNative ("SC_RemoveAllCronJobs", Native_RemoveAllCronJobs);
    return true;
}

public Native_AddCronJob (Handle:hPlugin, iNumParams)
{
    decl String:szJobTask[MAX_JOB_LEN] = "";
    static iLen = 0, iJobTime[JOB_TIME_SIZE];

    iJobTime[JOB_WEEKDAY_START] = GetNativeCell (1);
    iJobTime[JOB_WEEKDAY_END] = GetNativeCell (2);
    if (!SC_IsWeekdayValid (iJobTime[JOB_WEEKDAY_START]) || !SC_IsWeekdayValid (iJobTime[JOB_WEEKDAY_END]))
        return ThrowNativeError (SP_ERROR_NATIVE, "Weekday value is out of range - Maximum value is 6");

    iJobTime[JOB_HOUR_START] = GetNativeCell (3);
    iJobTime[JOB_HOUR_END] = GetNativeCell (4);
    if (!SC_IsHourValid (iJobTime[JOB_HOUR_START]) || !SC_IsHourValid (iJobTime[JOB_HOUR_END]))
        return ThrowNativeError (SP_ERROR_NATIVE, "Hour value is out of range - Maximum value is 23");

    iJobTime[JOB_MINUTE_START] = GetNativeCell (5);
    iJobTime[JOB_MINUTE_END] = GetNativeCell (6);
    if (!SC_IsMinuteValid (iJobTime[JOB_MINUTE_START]) || !SC_IsMinuteValid (iJobTime[JOB_MINUTE_END]))
        return ThrowNativeError (SP_ERROR_NATIVE, "Minute value is out of range - Maximum value is 59");
    
    GetNativeStringLength (7, iLen);
    GetNativeString (7, szJobTask, iLen + 1);
    if (szJobTask[0] == '\0')
        return ThrowNativeError (SP_ERROR_NATIVE, "No cron job specified");

    PushArrayArray (g_hJobsTimeArray, iJobTime);
    return PushArrayString (g_hJobsTaskArray, szJobTask);
}

public Native_SearchCronJobId (Handle:hPlugin, iNumParams)
{
    new iSearchJobTime[JOB_TIME_SIZE], iLen, iArraySize, iArrayIndex, iJobTime[JOB_TIME_SIZE];
    decl String:szSearchJob[MAX_JOB_LEN] = "", String:szCronJob[MAX_JOB_LEN] = "";
    
    iSearchJobTime[JOB_WEEKDAY_START] = GetNativeCell (1);
    iSearchJobTime[JOB_WEEKDAY_END] = GetNativeCell (2);
    if (!SC_IsWeekdayValid (iSearchJobTime[JOB_WEEKDAY_START]) || !SC_IsWeekdayValid (iSearchJobTime[JOB_WEEKDAY_END]))
        return -1;

    iSearchJobTime[JOB_HOUR_START] = GetNativeCell (3);
    iSearchJobTime[JOB_HOUR_END] = GetNativeCell (4);
    if (!SC_IsHourValid (iSearchJobTime[JOB_HOUR_START]) || !SC_IsHourValid (iSearchJobTime[JOB_HOUR_END]))
        return -1;

    iSearchJobTime[JOB_MINUTE_START] = GetNativeCell (5);
    iSearchJobTime[JOB_MINUTE_END] = GetNativeCell (6);
    if (!SC_IsMinuteValid (iSearchJobTime[JOB_MINUTE_START]) || !SC_IsMinuteValid (iSearchJobTime[JOB_MINUTE_END]))
        return -1;

    GetNativeStringLength (7, iLen);
    GetNativeString (7, szSearchJob, iLen + 1);

    iArraySize = GetArraySize (g_hJobsTimeArray);

    if (iArraySize > 0)
    {
        iArrayIndex = 0;
        while (iArrayIndex < iArraySize)
        {
            GetArrayArray (g_hJobsTimeArray, iArrayIndex, iJobTime);

            if ((iSearchJobTime[JOB_WEEKDAY_START] == iJobTime[JOB_WEEKDAY_START]) &&
                (iSearchJobTime[JOB_WEEKDAY_END] == iJobTime[JOB_WEEKDAY_END]))
            {
                if ((iSearchJobTime[JOB_HOUR_START] == iJobTime[JOB_HOUR_START]) &&
                    (iSearchJobTime[JOB_HOUR_END] == iJobTime[JOB_HOUR_END]))
                {
                    if ((iSearchJobTime[JOB_MINUTE_START] == iJobTime[JOB_MINUTE_START]) &&
                        (iSearchJobTime[JOB_MINUTE_END] == iJobTime[JOB_MINUTE_END]))
                    {
                        GetArrayString (g_hJobsTaskArray, iArrayIndex, szCronJob, sizeof (szCronJob));
                        if (!strcmp (szSearchJob, szCronJob, false))
                            return iArrayIndex;
                    }
                }
            }

            iArrayIndex++;
        }
    }

    return -1;
}

public Native_RemoveCronJob (Handle:hPlugin, iNumParams)
{
    static iJobIndex;

    iJobIndex = GetNativeCell (1);
    if (iJobIndex < GetArraySize (g_hJobsTimeArray))
    {
        RemoveFromArray (g_hJobsTimeArray, iJobIndex);
        RemoveFromArray (g_hJobsTaskArray, iJobIndex);
        return true;
    }
    
    return false;
}

public Native_GetNumberOfCronJobs (Handle:hPlugin, iNumParams)
{
    return GetArraySize (g_hJobsTimeArray) - 1;
}

public Native_GetCronJobFromId (Handle:hPlugin, iNumParams)
{
    static iCronJobId, iArraySize, iJobTime[JOB_TIME_SIZE];
    decl String:szCronJob[MAX_JOB_LEN] = "";

    iArraySize = GetArraySize (g_hJobsTimeArray);
    iCronJobId = GetNativeCell (1);

    if ((iArraySize == 0) || (iCronJobId > iArraySize))
        return false;

    GetArrayArray (g_hJobsTimeArray, iCronJobId, iJobTime);
    GetArrayString (g_hJobsTaskArray, iCronJobId, szCronJob, sizeof (szCronJob));
    SetNativeCellRef (2, iJobTime[JOB_WEEKDAY_START]);
    SetNativeCellRef (3, iJobTime[JOB_WEEKDAY_END]);
    SetNativeCellRef (4, iJobTime[JOB_HOUR_START]);
    SetNativeCellRef (5, iJobTime[JOB_HOUR_END]);
    SetNativeCellRef (6, iJobTime[JOB_MINUTE_START]);
    SetNativeCellRef (7, iJobTime[JOB_MINUTE_END]);
    SetNativeString (8, szCronJob, sizeof (szCronJob));
    return true;
}

public Native_RemoveAllCronJobs (Handle:hPlugin, iNumParams)
{
    if (g_hJobsTimeArray != INVALID_HANDLE)
    {
        ClearArray (g_hJobsTimeArray);
    }
    if (g_hJobsTaskArray != INVALID_HANDLE)
    {
        ClearArray (g_hJobsTaskArray);
    }
}

public Action:CrontabTimer (Handle:timer)
{
    new iArrayIndex, iArraySize, iJobTime[JOB_TIME_SIZE], iWeekday, iHour, iMinute;
    decl String:szCronJob[MAX_JOB_LEN] = "";

    iArraySize = GetArraySize (g_hJobsTimeArray);
    iWeekday = getWeekDay ();
    iHour = getHour ();
    iMinute = getMinute ();

    if (iArraySize > 0)
    {
        iArrayIndex = 0;
        while (iArrayIndex < iArraySize)
        {
            GetArrayArray (g_hJobsTimeArray, iArrayIndex, iJobTime);

            if (((iJobTime[JOB_WEEKDAY_START] <= iWeekday) || (iJobTime[JOB_WEEKDAY_START] == JOB_WILDCARD)) &&
			    ((iJobTime[JOB_WEEKDAY_END] >= iWeekday) || (iJobTime[JOB_WEEKDAY_END] == JOB_WILDCARD)))
            {
                if (((iJobTime[JOB_HOUR_START] <= iHour) || (iJobTime[JOB_HOUR_START] == JOB_WILDCARD)) &&
                    ((iJobTime[JOB_HOUR_END] >= iHour) || (iJobTime[JOB_HOUR_END] == JOB_WILDCARD)))
                {
                    if (((iJobTime[JOB_MINUTE_START] <= iMinute) || (iJobTime[JOB_MINUTE_START] == JOB_WILDCARD)) &&
                        ((iJobTime[JOB_MINUTE_START] >= iMinute) || (iJobTime[JOB_MINUTE_START] == JOB_WILDCARD)))
                    {
                        GetArrayString (g_hJobsTaskArray, iArrayIndex, szCronJob, sizeof (szCronJob));
                        
                        new Action:aResult = Plugin_Continue;
                        Call_StartForward (g_hCronCallForward);
                        Call_PushCell (iArrayIndex);
                        Call_PushString (szCronJob);
                        Call_Finish (aResult);
                        
                        if (aResult < Plugin_Handled)
                        {
                            LogMessage ("Running cron job \"%s\"", szCronJob);
                            ServerCommand (szCronJob);
						}
						else
						{
							LogMessage ("Skipping cron job \"%s\"", szCronJob);
						}
                    }
                }
            }

            iArrayIndex++;
        }
    }

    return Plugin_Continue;
}

stock getMinute ()
{
    decl String:szMinute[3] = "";

    FormatTime (szMinute, sizeof (szMinute), "%M");
    return StringToInt (szMinute);
}

stock getHour ()
{
    decl String:szHour[3] = "";

    FormatTime (szHour, sizeof (szHour), "%H");
    return StringToInt (szHour);
}

stock getWeekDay ()
{
    decl String:szWeekday[3] = "";

    FormatTime (szWeekday, sizeof (szWeekday), "%w");
    return StringToInt (szWeekday);
}

