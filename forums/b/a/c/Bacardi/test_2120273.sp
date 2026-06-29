
#include <sdktools>

new Handle:model_name;
new Handle:model_path;

public OnPluginStart()
{
	new String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "configs/models.txt");

	if(!FileExists(file))
	{
		SetFailState("No file - %s", file);
	}

	model_name = CreateArray(ByteCountToCells(MAX_NAME_LENGTH));
	model_path = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));

	new Handle:smc = SMC_CreateParser();
	SMC_SetReaders(smc, ns, kv, es);
	SMC_ParseFile(smc, file);

	RegConsoleCmd("sm_models", test);
}

public SMCResult:ns(Handle:smc, const String:name[], bool:opt_quotes){}
public SMCResult:kv(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	new dot = FindCharInString(value, '.', true);

	if(StrEqual(value[dot], ".mdl", false) && FileExists(value, true))
	{
		PushArrayString(model_name, key);
		PushArrayString(model_path, value);
		PrintToServer("%s %s", key, value)
	}
}
public SMCResult:es(Handle:smc){}

public Action:test(client, args)
{

	new Handle:menu = CreateMenu(menu_handler);
	SetMenuTitle(menu, "Models");

	new array_size = GetArraySize(model_name);
	new String:name[MAX_NAME_LENGTH];
	new String:path[PLATFORM_MAX_PATH];

	for(new a = 0; a < array_size; a++)
	{
		GetArrayString(model_name, a, name, sizeof(name));
		GetArrayString(model_path, a, path, sizeof(path));

		AddMenuItem(menu, path, name);
	}
	DisplayMenu(menu, client, 60);
	return Plugin_Handled;
}

public menu_handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			new String:infoBuf[PLATFORM_MAX_PATH];
			GetMenuItem(menu, param2, infoBuf, sizeof(infoBuf));
			PrecacheModel(infoBuf);
			SetEntityModel(param1, infoBuf);

			test(param1, 0);
		}
	}
}