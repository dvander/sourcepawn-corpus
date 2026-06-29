#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools_functions>
#include <actions>

ActionConstructor g_ActionConstructor_WitchAttack;

public void OnPluginStart()
{
	GameData gd = new GameData("test_actions_witch");
	if (gd == null)
		SetFailState("Missing gamedata (%s)", "test_actions_witch");

	g_ActionConstructor_WitchAttack = ActionConstructor.SetupFromConf(gd, "Forgetest::WitchAttack");
	delete gd;

	RegConsoleCmd("sm_gogo", gogo);
	RegConsoleCmd("sm_uei", uei);
}

Action gogo(int client, int args)
{
	int witch = FindEntityByClassname(MaxClients+1, "witch");
	if (IsValidEdict(witch))
	{
		BehaviorAction action = ActionsManager.GetAction(witch, "WitchBurn");

		if (action != INVALID_ACTION && action.Above != INVALID_ACTION)
		{
			action.Above.SetUserData("new_target", GetClientUserId(client));
			action.Above.Update = WitchAttack_OnUpdate;

			SDKHook(witch, SDKHook_OnTakeDamage, Witch_OnTakeDamage);
		}
	}

	return Plugin_Handled;
}

Action Witch_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (damagetype & DMG_BURN)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

Action WitchAttack_OnUpdate(BehaviorAction action, int actor, float interval, ActionResult result)
{
	action.Update = INVALID_FUNCTION;

	int userid = action.GetUserData("new_target");
	int client = GetClientOfUserId(userid);

	if (!IsValidPlayer(client))
		return Plugin_Continue;

	PrintToChatAll("\x04 new_target %N", client);
	return action.ChangeTo(g_ActionConstructor_WitchAttack.Execute(client), "WitchAttack_OnUpdate");
}

Action uei(int client, int args)
{
	int entity = FindEntityByClassname(MaxClients+1, "witch");
	if (entity != INVALID_ENT_REFERENCE)
	{
		BehaviorAction behavior = ActionsManager.GetAction(entity, "WitchBehavior");

		if (behavior != INVALID_ACTION)
		{
			DumpActionChains(behavior);

			for (BehaviorAction it = behavior.Child; it != INVALID_ACTION; it = it.Child)
			{
				DumpActionChains(it);
			}
		}
	}

	return Plugin_Handled;
}

void DumpActionChains(BehaviorAction action)
{
	ArrayList list = new ArrayList();
	list.Push(action);

	for (BehaviorAction it = action.Above; it != INVALID_ACTION; it = it.Above)
	{
		list.Push(it);
	}

	for (BehaviorAction it = action.Under; it != INVALID_ACTION; it = it.Under)
	{
		list.ShiftUp(0);
		list.Set(0, it);
	}

	char buffer[512], name[64];

	for (int i = list.Length-1; i >= 0; --i)
	{
		BehaviorAction it = list.Get(i);
		it.GetName(name);
		Format(name, sizeof(name), "%s:%X", name, it);
		StrCat(buffer, sizeof(buffer), name);
		StrCat(buffer, sizeof(buffer), "<<");
	}

	int len = strlen(buffer);
	if (len > 2)
	{
		buffer[len-2] = 0;
	}

	PrintToChatAll("%s", buffer);
}

stock bool IsValidPlayer(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}
