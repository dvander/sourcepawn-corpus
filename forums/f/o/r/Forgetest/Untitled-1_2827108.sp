#include <sourcemod>
#include <actions>
#include <sdktools_functions>
#include <left4dhooks>

ActionConstructor g_WitchAttackCtor;

public void OnPluginStart()
{
	GameData gd = new GameData("l4d2witchattack");
	g_WitchAttackCtor = ActionConstructor.SetupFromConf(gd, "WitchAttack::WitchAttack");
	delete gd;

	RegConsoleCmd("sm_test", Cmd_Test);
	RegConsoleCmd("sm_test2", Cmd_Test2);
}

Action Cmd_Test(int client, int args)
{
	int entity = FindEntityByClassname(MaxClients+1, "witch");
	if (entity != -1)
	{
		PrintToChatAll("\x03 Cmd_Test");
		func(entity);
	}
	return Plugin_Handled;
}

Action Cmd_Test2(int client, int args)
{
	int entity = FindEntityByClassname(MaxClients+1, "witch");
	if (entity != -1)
	{
		PrintToChatAll("\x03 Cmd_Test2");
		GetTopAction( ActionsManager.GetAction(entity, "WitchBehavior") );
	}
	return Plugin_Handled;
}

void func(int entity)
{
	BehaviorAction action = ActionsManager.GetAction(entity, "WitchBehavior");
	 if (action == INVALID_ACTION)
		return;
	
	action = GetTopAction(action);
	action.Update = OnUpdate;
}

public void OnActionCreated(BehaviorAction action, int actor, const char[] name)
{
	PrintToChatAll("\x05%.2f OnActionCreated \x04%s", GetGameTime(), name);
}

Action OnUpdate(BehaviorAction action, int actor, float interval, ActionResult result)
{
	int target = GetRandomSurvivor();
	PrintToChatAll("OnUpdate: target %N", target);
	return action.SuspendFor(g_WitchAttackCtor.Execute(target), "Forced by plugin");
}

BehaviorAction GetTopAction(BehaviorAction action)
{
	char name[ACTION_NAME_LENGTH];
	action.GetName(name);
	PrintToChatAll("\x04 GetTopAction: %s", name);
	
	while (action.Above)
	{
		action = action.Above;
		action.GetName(name);
		PrintToChatAll("\x04 GetTopAction: %s", name);
	}
	return action;
}
