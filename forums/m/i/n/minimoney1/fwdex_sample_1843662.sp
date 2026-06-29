#include <sourcemod>
#include <forwardex>

new Forward:g_fMyForward = INVALID_FORWARD;

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:err[], err_max)
{
	CreateNative("AddToMyForward", Native_Add);
	CreateNative("RemoveFromMyForward", Native_Remove);
	return APLRes_Success;
}

public Native_Add(Handle:plugin, numParams)
{
	if (g_fMyForward != INVALID_FORWARD)
	{
		FwdEx_AddToForward(g_fMyForward, plugin, Function:GetNativeCell(1));
	}
}

public Native_Remove(Handle:plugin, numParams)
{
	if (g_fMyForward != INVALID_FORWARD)
	{
		FwdEx_RemoveFromForward(g_fMyForward, plugin, Function:GetNativeCell(1));
	}
}

public OnPluginStart()
{
	FwdEx_Init();
	g_fMyForward = FwdEx_CreateForward();
}

public OnMapStart()
{
	if (g_fMyForward != INVALID_FORWARD)
	{
		new bool:finish = false;
		new bool:isTrue = true;
		new count = FwdEx_GetFwdCount(g_fMyForward);
		for (new i = 0; i < count; i++)
		{
			finish = false;
			Call_StartPrivateForward(g_fMyForward, ForwardId:i);
			Call_PushCellRef(isTrue);
			Call_Finish(finish);
			if (!finish)
			{
				isTrue = true;
			}
		}
	}
}

public OnPluginEnd()
{
	FwdEx_End();
}