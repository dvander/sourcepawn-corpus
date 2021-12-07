#pragma semicolon 1
#include <sourcemod>
#include <tz>

#pragma newdecls required

Database db = null;
Handle g_hQueryFwd;

int query_num;

public Plugin myinfo =
{
	name = "Timezone DB API",
	author = "Accelerator",
	description = "Time DB API in specific timezone",
	version = "1.0",
	url = "http://core-ss.org"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("TZ_GetTime", Native_TZGetTime); // Time in timezone
	CreateNative("TZ_GetTimeDST", Native_TZGetTimeDST); // Daylight Saving in Timezone
	CreateNative("TZ_GetTimeOffset", Native_TZGetTimeOffset); // Timezone offset

	RegPluginLibrary("TZ_API");
	
	return APLRes_Success;
}

public int Native_TZGetTime(Handle hPlugin, int numParams)
{
	if (db == null)
	{
		return -1;
	}

	char sTimezone[64];
	GetNativeString(1, sTimezone, sizeof(sTimezone));

	char sFormatTime[32];
	FormatTime(sFormatTime, sizeof(sFormatTime), "%Y-%m-%d %H:%M:%S");

	char query[320];
	Format(query, sizeof(query), "SELECT ((UNIX_TIMESTAMP() + TIMESTAMPDIFF(SECOND, '%s', UTC_TIMESTAMP())) + tz.gmt_offset) \
		FROM `timezone` tz JOIN `zone` z \
		ON tz.zone_id=z.zone_id \
		WHERE tz.time_start <= UNIX_TIMESTAMP(UTC_TIMESTAMP()) AND z.zone_name='%s' \
		ORDER BY tz.time_start DESC LIMIT 1;", sFormatTime, sTimezone);

	query_num++;
	db.Query(QueryFinished, query, query_num);

	return query_num;
}

public int Native_TZGetTimeDST(Handle hPlugin, int numParams)
{
	if (db == null)
	{
		return -1;
	}

	char sTimezone[64];
	GetNativeString(1, sTimezone, sizeof(sTimezone));

	char query[256];
	Format(query, sizeof(query), "SELECT tz.dst \
		FROM `timezone` tz JOIN `zone` z \
		ON tz.zone_id=z.zone_id \
		WHERE tz.time_start <= UNIX_TIMESTAMP(UTC_TIMESTAMP()) AND z.zone_name='%s' \
		ORDER BY tz.time_start DESC LIMIT 1;", sTimezone);

	query_num++;
	db.Query(QueryFinished, query, query_num);
	
	return query_num;
}

public int Native_TZGetTimeOffset(Handle hPlugin, int numParams)
{
	if (db == null)
	{
		return -1;
	}

	char sTimezone[64];
	GetNativeString(1, sTimezone, sizeof(sTimezone));

	char query[256];
	Format(query, sizeof(query), "SELECT tz.gmt_offset \
		FROM `timezone` tz JOIN `zone` z \
		ON tz.zone_id=z.zone_id \
		WHERE tz.time_start <= UNIX_TIMESTAMP(UTC_TIMESTAMP()) AND z.zone_name='%s' \
		ORDER BY tz.time_start DESC LIMIT 1;", sTimezone);

	query_num++;
	db.Query(QueryFinished, query, query_num);
	
	return query_num;
}

public void QueryFinished(Database hDatabase, DBResultSet results, const char[] error, int num)
{
	int ret_cell;

	if (results != null)
	{
		while (SQL_FetchRow(results))
		{
			ret_cell = SQL_FetchInt(results, 0);
		}
	}

	Call_StartForward(g_hQueryFwd);
	Call_PushCell(num);
	Call_PushCell(ret_cell);
	Call_Finish();
}

public void OnPluginStart()
{
	g_hQueryFwd = CreateGlobalForward("TZ_OnQueryFinished", ET_Ignore, Param_Cell, Param_Cell);
	ConnectDB();
}

public void OnMapStart()
{
	if (db == null)
		ConnectDB();
}

public void ConnectDB()
{
	if (SQL_CheckConfig("tzdb"))
	{
		char Error[256];
		db = SQL_DefConnect(Error, sizeof(Error), true);

		if (db == null)
			LogError("Failed to connect to database: %s", Error);
		else
		{
			if (!SQL_FastQuery(db, "SET NAMES 'utf8'"))
			{
				SQL_GetError(db, Error, sizeof(Error));
				LogError("SQL Error: %s", Error);
			}
		}
	}
	else
		LogError("Database.cfg missing 'tzdb' entry!");
}