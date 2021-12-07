#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	RegAdminCmd("sm_refillammo", Command_refillammo, ADMFLAG_CHEATS);
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
}

public Action:Command_refillammo(client, args)
{
	if (client == 0)
	{
		PrintToServer("[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[SM] %t", "Target must be alive");
		return Plugin_Handled;
	}
	new Float:Pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", Pos);
	new Ent = CreateEntityByName("item_ammopack_full");
	DispatchSpawn(Ent);
	ActivateEntity(Ent);
	TeleportEntity(Ent, Pos, NULL_VECTOR, NULL_VECTOR);
	CreateTimer(0.1, DestroyAmmo, Ent);
	return Plugin_Handled;
}

public Action:DestroyAmmo(Handle:timer, any:Ent)
{
	if (!IsValidEntity(Ent)) return Plugin_Handled;
	new String:cls[20];
	GetEntityClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "item_ammopack_full"))
		AcceptEntityInput(Ent, "Kill");
	return Plugin_Handled;
}