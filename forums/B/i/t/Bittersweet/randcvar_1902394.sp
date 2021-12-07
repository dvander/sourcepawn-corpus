#include <sourcemod>

new const String:PLUGIN_NAME[]= "randcvar"
new const String: PLUGIN_AUTHOR[]= "Bittersweet"
new const String:PLUGIN_DESCRIPTION[]= "Assigns random values to cvars as defined in the configs/randcvars.cfg file."
new const String: PLUGIN_VERSION[]= "2013.02.26.11.40"

new String:errormessage[1024]
new String:rand_cvar_filename[PLATFORM_MAX_PATH]
new String:cvar_list_item[1024]
new String:cvar_name[256]
new String:cvar_rand_type[5]
new String:cvar_int_lo[16]
new String:cvar_int_hi[16]
new String:cvar_list_count[16]
new String:cvar_list_pointer[16]
new String:cvar_float_prec[3]
new String:cvar_float_lo[32]
new String:cvar_float_hi[32]


new Handle:kv = INVALID_HANDLE
new Handle:g_cvar = INVALID_HANDLE

new Float:rand_float_low = 0.0
new Float:rand_float_high  = 0.0

new rand_int_low
new rand_int_high
new rand_float_prec
new rand_list_count
new rand_list_select
new success

new bool:DEBUG = false

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}
public OnPluginStart()
{
	PrintToServer("[%s %s] - Loaded", PLUGIN_NAME, PLUGIN_VERSION)
	SetRandomSeed(GetTime())
	kv = CreateKeyValues("Randomized_Cvars")  //Creates structure in memory...cannot fail???
	if (kv == INVALID_HANDLE)
	{
		Format(errormessage, sizeof(errormessage), "%s - Something went wrong assigning key values to 'Randomized_Cvars'", PLUGIN_NAME)
		ReportError(errormessage)
		UnloadMyself()
	}
	BuildPath(Path_SM, rand_cvar_filename, PLATFORM_MAX_PATH, "configs/randcvars.cfg")
	if (!FileToKeyValues(kv, rand_cvar_filename))
	{
		Format(errormessage, sizeof(errormessage), "File %s missing, aborting...", rand_cvar_filename)
		ReportError(errormessage)
		CloseHandle(kv)
		UnloadMyself()
	}
	LoadKeyValues()
}
public LoadKeyValues()
{
	if (!KvGetSectionName(kv, cvar_name, sizeof(cvar_name)))
	{
		Format(errormessage, sizeof(errormessage), "No Randomized_Cvars header in %s, aborting...", rand_cvar_filename)
		ReportError(errormessage)
		CloseHandle(kv)
		UnloadMyself()
	}
	if (!StrEqual(cvar_name, "Randomized_Cvars"))
	{
		Format(errormessage, sizeof(errormessage), "First section should be 'Randomized_Cvars' in %s, aborting...", rand_cvar_filename)
		ReportError(errormessage)
		CloseHandle(kv)
		UnloadMyself()
	}
	if (KvGotoFirstSubKey(kv))
	{
		GetNextDefinedCvar()
	}
	else
	{
		Format(errormessage, sizeof(errormessage), "No cvars defined in %s, aborting...", rand_cvar_filename)
		ReportError(errormessage)
		CloseHandle(kv)
		UnloadMyself()
	}
	while (KvGotoNextKey(kv))
	{
		GetNextDefinedCvar()
	}
	UnloadMyself()
}
public GetNextDefinedCvar()
{	if (!KvGetSectionName(kv, cvar_name, sizeof(cvar_name)))
	{
		Format(errormessage, sizeof(errormessage), "No cvars defined as sections in %s, aborting...", rand_cvar_filename)
		ReportError(errormessage)
		CloseHandle(kv)
		UnloadMyself()
	}
	g_cvar = INVALID_HANDLE
	g_cvar = FindConVar(cvar_name)
	if (g_cvar == INVALID_HANDLE)
	{
		Format(errormessage, sizeof(errormessage), "No such Cvar %s; randcvar does not create new cvars, aborting...", cvar_name)
		ReportError(errormessage)
		CloseHandle(kv)
		UnloadMyself()
	}
	GetRandCvarOptions()
}
public GetRandCvarOptions()
{
	KvGetString(kv, "type", cvar_rand_type, sizeof(cvar_rand_type))
	if (StrEqual(cvar_rand_type, "I", false))
	{
		//Integer Type
		if (DEBUG) PrintToServer("%s is type %s", cvar_name, cvar_rand_type)
		KvGetString(kv, "lo", cvar_int_lo, sizeof(cvar_int_lo))
		success = StringToIntEx(cvar_int_lo, rand_int_low)
		if (!success) rand_int_low = 0
		KvGetString(kv, "hi", cvar_int_hi, sizeof(cvar_int_hi))
		success = StringToIntEx(cvar_int_hi, rand_int_high)
		if (!success) rand_int_high = rand_int_low
		new newcvarvalue = GetRandomInt(rand_int_low, rand_int_high)
		SetConVarInt(g_cvar, newcvarvalue, true, true)
		if (DEBUG) PrintToServer("New random value=%i", newcvarvalue)
	}
	else if (StrEqual(cvar_rand_type, "F", false))
	{
		//Float type
		if (DEBUG) PrintToServer("%s is type %s", cvar_name, cvar_rand_type)
		KvGetString(kv, "prec", cvar_float_prec, sizeof(cvar_float_prec))
		success = StringToIntEx(cvar_float_prec, rand_float_prec)
		if (!success || rand_float_prec < 1 || rand_float_prec > 99)
		{
			Format(errormessage, sizeof(errormessage), "No precision or invalid precision (1-99 valid) for Float type cvar %s, aborting...", cvar_name)
			ReportError(errormessage)
			CloseHandle(kv)
			UnloadMyself()
		}
		KvGetString(kv, "lo", cvar_float_lo, sizeof(cvar_float_lo))
		success = StringToFloatEx(cvar_float_lo, rand_float_low)
		if (!success) rand_float_low = 0.0
		KvGetString(kv, "hi", cvar_float_hi, sizeof(cvar_float_hi))
		success = StringToFloatEx(cvar_float_hi, rand_float_high)
		if (!success) rand_float_high = rand_float_low
		new Float:tempcvarvalue = GetRandomFloat(rand_float_low, rand_float_high)
		new rand_float_whole = RoundToFloor(tempcvarvalue)
		new Float:rand_float_decimal = FloatFraction(tempcvarvalue)
		if (DEBUG) PrintToServer("Float whole=%i, fraction=%f", rand_float_whole, rand_float_decimal)
		decl String:dectempstr[32]
		FloatToString(rand_float_decimal, dectempstr, sizeof(dectempstr))
		decl String:parts[2][32]
		ExplodeString(dectempstr, ".", parts, sizeof(parts), sizeof(parts[]))
		Format(dectempstr, sizeof(dectempstr), "%s", parts[1])
		while (strlen(dectempstr) < rand_float_prec)
		{
			Format(dectempstr, sizeof(dectempstr), "%s0", dectempstr)
		}
		Format(dectempstr, rand_float_prec + 1, "%s", dectempstr)
		new String:newcvarvalue[32]
		Format(newcvarvalue, sizeof(newcvarvalue), "%i.%s", rand_float_whole, dectempstr) 
		if (DEBUG) PrintToServer("Reformatted float cvar=%s", newcvarvalue)
		new Float:newcvarvalue_as_float
		StringToFloatEx(newcvarvalue, newcvarvalue_as_float)
		SetConVarFloat(g_cvar, newcvarvalue_as_float, true, true)
	}
	else if (StrEqual(cvar_rand_type, "L", false))
	{
		//List type
		if (DEBUG) PrintToServer("%s is type %s", cvar_name, cvar_rand_type)
		KvGetString(kv, "count", cvar_list_count, sizeof(cvar_list_count))
		success = StringToIntEx(cvar_list_count, rand_list_count)
		if (!success || rand_list_count < 1)
		{
			Format(errormessage, sizeof(errormessage), "No count entry or list count less than 1 for %s, aborting...", cvar_name)
			ReportError(errormessage)
			CloseHandle(kv)
			UnloadMyself()
		}
		if (DEBUG) PrintToServer("List count for %s=%i", cvar_name, rand_list_count)
		rand_list_select = GetRandomInt(1, rand_list_count)
		for (new i = 1; i <= rand_list_count; i++)
		{
			Format(cvar_list_pointer, sizeof(cvar_list_pointer), "Item %i", i)
			KvGetString(kv, cvar_list_pointer, cvar_list_item, sizeof(cvar_list_item))
			if (DEBUG) PrintToServer("Found item %s for %s", cvar_list_item, cvar_name)
			if (i == rand_list_select)
			{
				if (DEBUG) PrintToServer("Item %s selected for %s", cvar_list_item, cvar_name)
				SetConVarString(g_cvar, cvar_list_item, true, true)
				break
			}
		}
	}
	else
	{
		Format(errormessage, sizeof(errormessage), "Invalid cvar type %s for %s, aborting...", cvar_rand_type, cvar_name)
		ReportError(errormessage)
		CloseHandle(kv)
		UnloadMyself()
	}
}
public UnloadMyself()
{
	ServerCommand("sm plugins unload randcvar")
}
public ReportError(const String:errmsg[])
{
	PrintToServer("%s", errmsg)
	LogError("%s", errmsg)
}
	
//End of Code