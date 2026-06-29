#include <sourcemod>

ConVar g_cvRealoadTimeCvar = null;

public Plugin myinfo =  {

	name = "Auto Reload Admin Cache",
	author = "Addicted",
	version = "1.0",

};

public void OnPluginStart() {

	g_cvRealoadTimeCvar = CreateConVar("sm_reload_admins_auto_time", "10", "Amount of minutes to wait before reloading admin cache", _, true, 1.0);

	CreateTimer(60.0 * g_cvRealoadTimeCvar.IntValue, ReloadAdminCacheTimer, _, TIMER_REPEAT);

}

public Action ReloadAdminCacheTimer(Handle timer) {

	DumpAdminCache(AdminCache_Groups, true);
	DumpAdminCache(AdminCache_Overrides, true);

}