#include <sourcemod>
#include <zephstocks>

public Plugin myinfo = {
 name = "Kewaii Library",
 author = "Kewaii",
 description = "Open Source library that has an wide range of uses",
 version = "1.2.1",
};

int g_cvarVIPFlag = -1;
int g_cvarModFlag = -1;
int g_cvarAdminFlag = -1;

public OnPluginStart()
{
	g_cvarVIPFlag = RegisterConVar("sm_kewaii_vip_flag", "o", "Flag for VIP access (all items unlocked). Leave blank to disable.", TYPE_FLAG);
	g_cvarModFlag = RegisterConVar("sm_kewaii_mod_flag", "b", "Flag for Mod access. Leave blank to disable.", TYPE_FLAG);
	g_cvarAdminFlag = RegisterConVar("sm_kewaii_admin_flag", "e", "Flag for Admin access. Leave blank to disable.", TYPE_FLAG);
	AutoExecConfig(true, "kewaii_lib");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Kewaii_IsClientVIP", Native_IsClientVIP);
	CreateNative("Kewaii_IsClientMod", Native_IsClientMod);
	CreateNative("Kewaii_IsClientAdmin", Native_IsClientAdmin);
	return APLRes_Success;
}

public Native_IsClientVIP(Handle plugin, numParams)
{
	return CheckCommandAccess(GetNativeCell(1), "", g_eCvars[g_cvarVIPFlag][aCache], true);
}

public Native_IsClientMod(Handle plugin, numParams)
{
	return CheckCommandAccess(GetNativeCell(1), "", g_eCvars[g_cvarModFlag][aCache], true);
}

public Native_IsClientAdmin(Handle plugin, numParams)
{
	return CheckCommandAccess(GetNativeCell(1), "", g_eCvars[g_cvarAdminFlag][aCache], true);
}