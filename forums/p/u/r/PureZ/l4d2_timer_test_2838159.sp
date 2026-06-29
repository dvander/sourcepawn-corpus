#include <sourcemod>
#include <l4d2_timer>

ArrayList handleInParamsDontDispose;
ArrayList handleInParamsAutoDispose;
L4D2TimerParamPack params;
int pos[3];
float ang[3];
char name[64];

public Plugin L4D2TimerTestPluginInfo =
{
    name = "L4D2 Timer Test",
    author = "Pure_*",
    description = "Test cases for L4D2 Timer",
    version = "0.1",
    url = "URL"
};

// !rcon sm plugins reload l4d2_timer_test
public void OnPluginStart()
{

    pos[0] = 2025;
    pos[1] = 2026;
    pos[2] = 2027;

    ang[0] = 76.2;
    ang[1] = -896.2;
    ang[2] = 456.2;

    strcopy(name, 64, "Parameter String");

    handleInParamsDontDispose = new ArrayList();
    handleInParamsDontDispose.Push(2025);
    handleInParamsDontDispose.Push(7);
    handleInParamsDontDispose.Push(6);

    handleInParamsAutoDispose = new ArrayList();
    handleInParamsAutoDispose.Push(2050);
    handleInParamsAutoDispose.Push(10);
    handleInParamsAutoDispose.Push(1);

    params = new L4D2TimerParamPack();
    params.PushInt(7355608);
    params.PushFloat(3.141592);
    params.PushString(name);
    params.PushIntArray(pos, 3);
    params.PushFloatArray(ang, 3);
    params.PushHandle(handleInParamsAutoDispose);
    params.PushHandle(handleInParamsDontDispose, false);

    RegConsoleCmd("sm_testdf", Command_DelayFrames_Test);
    RegConsoleCmd("sm_testdfp", Command_DelayFrames_WithParameters_Test);
    RegConsoleCmd("sm_testd", Command_Delay_Test);
    RegConsoleCmd("sm_testdp", Command_Delay_WithParameters_Test);
    RegConsoleCmd("sm_testuf", Command_UpdateFrames_Test);
    RegConsoleCmd("sm_testufp", Command_UpdateFrames_WithParameters_Test);
    RegConsoleCmd("sm_testu", Command_Update_Test);
    RegConsoleCmd("sm_testup", Command_Update_WithParameters_Test);
    RegConsoleCmd("sm_testr", Command_Repeat_Test);
    RegConsoleCmd("sm_testrp", Command_Repeat_WithParameters_Test);
    RegConsoleCmd("sm_testdispose", Command_Dispose_Test);
    RegConsoleCmd("sm_testparamautodispose", Command_Param_Auto_Dispose_Test);
}

Action Command_DelayFrames_Test(int client, int args)
{
    // work
    PrintToChatAll("[TimerTest] DelayFrames_Test Call At %f", GetGameTime());
    L4D2_Timer_DelayFrames(client, 10, TimerTest_Print);
    return Plugin_Continue;
}

Action Command_DelayFrames_WithParameters_Test(int client, int args)
{
    // work
    PrintToChatAll("[TimerTest] DelayFrames_WithParameters_Test Call At %f", GetGameTime());
    L4D2_Timer_DelayFrames_WithParameters(client, 10, TimerTest_Print_WithParameters, view_as<L4D2TimerParamPack>(params.Clone()));
    return Plugin_Continue;
}

Action Command_Delay_Test(int client, int args)
{
    // work
    PrintToChatAll("[TimerTest] Delay_Test Call At %f", GetGameTime());
    L4D2_Timer_Delay(client, 3.0, TimerTest_Print);
    return Plugin_Continue;
}

Action Command_Delay_WithParameters_Test(int client, int args)
{
    // work
    PrintToChatAll("[TimerTest] Delay_WithParameters_Test Call At %f", GetGameTime());
    L4D2_Timer_Delay_WithParameters(client, 3.0, TimerTest_Print_WithParameters, view_as<L4D2TimerParamPack>(params.Clone()));
    return Plugin_Continue;
}

Action Command_UpdateFrames_Test(int client, int args)
{
    // work
    PrintToChatAll("[TimerTest] UpdateFrames_Test Call At %f", GetGameTime());
    L4D2_Timer_UpdateFrames(client, 10, TimerTest_Print);
    return Plugin_Continue;
}

Action Command_UpdateFrames_WithParameters_Test(int client, int args)
{
    // work
    PrintToChatAll("[TimerTest] UpdateFrames_WithParameters_Test Call At %f", GetGameTime());
    L4D2_Timer_UpdateFrames_WithParameters(client, 10, TimerTest_Print_WithParameters, view_as<L4D2TimerParamPack>(params.Clone()));
    return Plugin_Continue;
}

Action Command_Update_Test(int client, int args)
{
    // work
    PrintToChatAll("[TimerTest] Update_Test Call At %f", GetGameTime());
    L4D2_Timer_Update(client, 2.0, TimerTest_Print);
    return Plugin_Continue;
}

Action Command_Update_WithParameters_Test(int client, int args)
{
    // work
    PrintToChatAll("[TimerTest] Update_WithParameters_Test Call At %f", GetGameTime());
    L4D2_Timer_Update_WithParameters(client, 2.0, TimerTest_Print_WithParameters, view_as<L4D2TimerParamPack>(params.Clone()));
    return Plugin_Continue;
}

Action Command_Repeat_Test(int client, int args)
{
    // work
    PrintToChatAll("[TimerTest] Repeat_Test Call At %f", GetGameTime());
    L4D2_Timer_Repeat(client, 5, 2.0, TimerTest_Print);
    return Plugin_Continue;
}

Action Command_Repeat_WithParameters_Test(int client, int args)
{
    // work
    PrintToChatAll("[TimerTest] Repeat_WithParameters_Test Call At %f", GetGameTime());
    L4D2_Timer_Repeat_WithParameters(client, 5, 2.0, TimerTest_Print_WithParameters, view_as<L4D2TimerParamPack>(params.Clone()));
    return Plugin_Continue;
}

Action Command_Dispose_Test(int client, int args)
{
    // work
    PrintToChatAll("[TimerTest] Dispose_Test Call At %f", GetGameTime());
    Handle h = L4D2_Timer_UpdateFrames_WithParameters(client, 5, TimerTest_Print_WithParameters, view_as<L4D2TimerParamPack>(params.Clone()));
    L4D2_Timer_Dispose(h);
    return Plugin_Continue;
}

Action Command_Param_Auto_Dispose_Test(int client, int args)
{
    // work
    PrintToChatAll("[TimerTest] Param_Auto_Dispose_Test Call At %f", GetGameTime());
    L4D2TimerParamPack p = new L4D2TimerParamPack();
    p.PushHandle(handleInParamsAutoDispose.Clone());
    p.FreeParameters();

    ArrayList arr = view_as<ArrayList>(p.Get(0));
    // Raise error when arr.Length
    for(int i = 0; i < arr.Length; i++)
    {
        PrintToChatAll("[TimerTest] Param_Auto_Dispose_Test Param = %d", view_as<int>(arr.Get(i)));
    }
    return Plugin_Continue;
}

//    ---------------------- Test Functions ----------------------------------------------
void TimerTest_Print(int entity)
{
    PrintToChatAll("[TimerTest] TimerTest_Print Called At %f", GetGameTime());
}

void TimerTest_Print_WithParameters(int entity, L4D2TimerParamPack parameters)
{
    for(int i = 0; i < parameters.Length; i++)
    {
        StringMap parameter = view_as<StringMap>(parameters.Get(i));
        L4D2TimerParamType type;
        if(parameter.GetValue("type", type))
        {
            switch(type)
            {
                case L4D2Timer_Param_Int:
                {
                    int value;
                    parameter.GetValue("value", value);
                    // PrintToChatAll("[TimerTest] Param Int = %d", value);
                }
                case L4D2Timer_Param_Float:
                {
                    float value;
                    parameter.GetValue("value", value);
                    // PrintToChatAll("[TimerTest] Param Float = %f", value);
                }
                case L4D2Timer_Param_String:
                {
                    char value[64];
                    parameter.GetString("value", value, 64);
                    // PrintToChatAll("[TimerTest] Param String = %s", value);
                }
                case L4D2Timer_Param_IntArray:
                {
                    int value[3];
                    parameter.GetArray("value", value, 3);
                    // PrintToChatAll("[TimerTest] Param IntArray = {%d, %d, %d}", value[0], value[1], value[2]);
                }
                case L4D2Timer_Param_FloatArray:
                {
                    float value[3];
                    parameter.GetArray("value", value, 3);
                    // PrintToChatAll("[TimerTest] Param FloatArray = {%f, %f, %f}", value[0], value[1], value[2]);
                }
                case L4D2Timer_Param_Handle_Auto_Dispose:
                {
                    Handle value;
                    parameter.GetValue("value", value);
                    ArrayList arr = view_as<ArrayList>(value);
                    char str[64];
                    for(int j = 0; j < arr.Length; j++)
                    {
                        Format(str, 64, "%s %d", str, view_as<int>(arr.Get(j)));
                    }
                    // PrintToChatAll("[TimerTest] Param Handle Auto Dispose = {%s}", str);
                }
                case L4D2Timer_Param_Handle_Dont_Dispose:
                {
                    Handle value;
                    parameter.GetValue("value", value);
                    ArrayList arr = view_as<ArrayList>(value);
                    char str[64];
                    for(int j = 0; j < arr.Length; j++)
                    {
                        Format(str, 64, "%s %d", str, view_as<int>(arr.Get(j)));
                    }
                    // PrintToChatAll("[TimerTest] Param Handle Dont Dispose = {%s}", str);
                }
            }
        }
    }
    PrintToChatAll("[TimerTest] TimerTest_Print_WithParameters Call At %f", GetGameTime());
}