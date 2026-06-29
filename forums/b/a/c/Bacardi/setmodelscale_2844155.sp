

#include <sdktools>

public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	RegAdminCmd("sm_setmodelscale", setmodelscale, ADMFLAG_CHEATS, "Change player size");
}

public Action setmodelscale(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM]Usage: sm_setmodelscale <name|userid|@alive> [scale 0.1~10.0] [seconds 0.0~300.0]");
		return Plugin_Handled;
	}

	int[] targets = new int[MaxClients];

	char target_name[MAX_NAME_LENGTH];
	bool tn_is_ml = false;

	char arg[MAX_NAME_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));

	int count;
	if((count = ProcessTargetString(arg,
						client,
						targets, MaxClients,
						COMMAND_FILTER_ALIVE,
						target_name, sizeof(target_name),
						tn_is_ml)) <= COMMAND_TARGET_NONE)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}

	float scale = 1.0;

	if(args >= 2)
	{
		arg[0] = '\0';
		GetCmdArg(2, arg, sizeof(arg));
		scale = StringToFloat(arg);
		
		if(scale <= 0.0)
			scale = 1.0;

		if(scale < 0.1)
			scale = 0.1;

		if(scale > 10.0)
			scale = 10.0;
	}

	float time = 3.0;

	if(args >= 3)
	{
		arg[0] = '\0';
		GetCmdArg(3, arg, sizeof(arg));
		time = StringToFloat(arg);
		
		if(time <= 0.0)
			time = 0.0;

		if(time > 300.0)
			time = 300.0;
	}



	tn_is_ml ?	ShowActivity2(client, "\x03[SM] ", "Model scale set %0.1f to: %s's", scale, target_name) :
				ShowActivity2(client, "\x03[SM] ", "Model scale set %0.1f to: %s", scale, target_name);

	

	char buffer[30];
	Format(buffer, sizeof(buffer), "%0.1f %0.1f", scale, time);

	for(int i = 0; i < count; i ++)
	{
		LogAction(client, targets[i], "(%L) Model scale %0.1f targeted to: %s (%L)", client, scale, target_name, targets[i]);
		SetVariantString(buffer);
		AcceptEntityInput(targets[i], "SetModelScale");
	}

	return Plugin_Handled;
}

