#include <sourcemod>
#include <sdkhooks>

public void OnEntityCreated(int entity, const char[] classname)
{
	if(strcmp(classname, "trigger_once") == 0)
	{
		SDKHook(entity, SDKHook_Touch, OnTriggerTouch);
	}
}

public Action OnTriggerTouch(int trigger, int other)
{
	char class[32];
	GetEdictClassname(other, class, sizeof(class));

	if(strcmp(class, "tf_dropped_weapon") == 0)
	{
		// Block the touch.
		return Plugin_Stop;
	}

	return Plugin_Continue;
}