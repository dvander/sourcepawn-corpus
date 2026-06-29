#include <sourcemod>
#include <l4d2_timer>

ArrayStack idCache;
ArrayList timerUserHandles;
ArrayList timerCallers;  // All Int
ArrayList timerDurations;  // All Float
ArrayList timerIntervals;  // All Float(only use in repeat timer)
ArrayList timerNextCallTimes;  // All Float(only use in repeat timer)
ArrayList timerPlugins;  // All Plugin
ArrayList timerFunctions;  // All Function (typeset L4D2TimerHandler) -> Int
ArrayList timerParameters; // All L4D2TimerParamPack
ArrayList timerCreateTimes;  // All Float
ArrayList timerFlags; // All Boolean

public Plugin L4D2TimerPluginInfo =
{
    name = "L4D2 Timer",
    author = "Pure_*",
    description = "Convenient timer to use",
    version = "0.1",
    url = "N/A"
};


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion version = GetEngineVersion();
    if(version != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only support on Left 4 Dead 2");
        return APLRes_SilentFailure;
    }

    RegPluginLibrary("l4d2_timer");
    CreateNative("L4D2_Timer_DelayFrames", Native_Timer_DelayFrames);
    CreateNative("L4D2_Timer_DelayFrames_WithParameters", Native_Timer_DelayFrames_WithParameters);
    CreateNative("L4D2_Timer_Delay", Native_Timer_Delay);
    CreateNative("L4D2_Timer_Delay_WithParameters", Native_Timer_Delay_WithParameters);
    CreateNative("L4D2_Timer_UpdateFrames", Native_Timer_UpdateFrames);
    CreateNative("L4D2_Timer_UpdateFrames_WithParameters", Native_Timer_UpdateFrames_WithParameters);
    CreateNative("L4D2_Timer_Update", Native_Timer_Update);
    CreateNative("L4D2_Timer_Update_WithParameters", Native_Timer_Update_WithParameters);
    CreateNative("L4D2_Timer_Repeat", Native_Timer_Repeat);
    CreateNative("L4D2_Timer_Repeat_WithParameters", Native_Timer_Repeat_WithParameters);
    CreateNative("L4D2_Timer_Dispose", Native_Timer_Dispose);

    return APLRes_Success;
}

public any Native_Timer_DelayFrames(Handle plugin, int numParams)
{
    int entity = GetNativeCell(1);
    if(!IsValidEntity(entity))
    {
        LogError("Entity %d is Invalid, Timer Disposed Automatically", entity);
        return -1;
    }

    int frames = GetNativeCell(2);
    if(frames <= 0)
    {
        LogError("Frames can not less than or equal 0, Timer Disposed Automatically");
        return -1;
    }

    Function func = GetNativeFunction(3);
    if(func == INVALID_FUNCTION)
    {
        char pluginName[64];
        GetPluginFilename(plugin, pluginName, 64);
        LogError("Function can not find in plugin %s, Timer Disposed Automatically", pluginName);
        return -1;
    }

    int timerID = PushIntoSequence(entity, float(frames), plugin, view_as<int>(func));

    DelayFrames(timerID);
    
    return CreateUserHandle(timerID);
}


public any Native_Timer_DelayFrames_WithParameters(Handle plugin, int numParams)
{
    int entity = GetNativeCell(1);
    if(!IsValidEntity(entity))
    {
        LogError("Entity %d is Invalid, Timer Disposed Automatically", entity);
        return -1;
    }

    int frames = GetNativeCell(2);
    if(frames <= 0)
    {
        LogError("Frames can not less than or equal 0, Timer Disposed Automatically");
        return -1;
    }

    Function func = GetNativeFunction(3);
    if(func == INVALID_FUNCTION)
    {
        char pluginName[64];
        GetPluginFilename(plugin, pluginName, 64);
        LogError("Function can not find in plugin %s, Timer Disposed Automatically", pluginName);
        return -1;
    }

    L4D2TimerParamPack params = view_as<L4D2TimerParamPack>(GetNativeCell(4));

    int timerID = PushIntoSequence(entity, float(frames), plugin, view_as<int>(func), params);
    
    DelayFrames(timerID);
    return CreateUserHandle(timerID);
}

void DelayFrames(int timerID)
{
    if(!view_as<bool>(timerFlags.Get(timerID)))
    {
        return;
    }
    else
    {
        int frames = RoundToNearest(view_as<float>(timerDurations.Get(timerID)));
        if(frames > 0)
        {
            timerDurations.Set(timerID, float(frames - 1));
            RequestFrame(DelayFrames, timerID);
        }
        else
        {
            CallFunction(timerID);
            DisposeTimer(timerID);
        }
    }
}

public any Native_Timer_Delay(Handle plugin, int numParams)
{
    int entity = GetNativeCell(1);
    if(!IsValidEntity(entity))
    {
        LogError("Entity %d is Invalid, Timer Disposed Automatically", entity);
        return -1;
    }

    float seconds = GetNativeCell(2);
    if(seconds <= 0.0)
    {
        LogError("Seconds can not less than or equal 0, Timer Disposed Automatically");
        return -1;
    }

    Function func = GetNativeFunction(3);
    if(func == INVALID_FUNCTION)
    {
        char pluginName[64];
        GetPluginFilename(plugin, pluginName, 64);
        LogError("Function can not find in plugin %s, Timer Disposed Automatically", pluginName);
        return -1;
    }

    int timerID = PushIntoSequence(entity, seconds + GetGameTime(), plugin, view_as<int>(func));
    
    Delay(timerID);

    return CreateUserHandle(timerID);
}

public any Native_Timer_Delay_WithParameters(Handle plugin, int numParams)
{
    int entity = GetNativeCell(1);
    if(!IsValidEntity(entity))
    {
        LogError("Entity %d is Invalid, Timer Disposed Automatically", entity);
        return -1;
    }

    float seconds = GetNativeCell(2);
    if(seconds <= 0.0)
    {
        LogError("Seconds can not less than or equal 0, Timer Disposed Automatically");
        return -1;
    }

    Function func = GetNativeFunction(3);
    if(func == INVALID_FUNCTION)
    {
        char pluginName[64];
        GetPluginFilename(plugin, pluginName, 64);
        LogError("Function can not find in plugin %s, Timer Disposed Automatically", pluginName);
        return -1;
    }
    L4D2TimerParamPack params = view_as<L4D2TimerParamPack>(GetNativeCell(4));

    int timerID = PushIntoSequence(entity, seconds + GetGameTime(), plugin, view_as<int>(func), params);

    Delay(timerID);
    return CreateUserHandle(timerID);
}

void Delay(int timerID)
{
    if(!view_as<bool>(timerFlags.Get(timerID)))
    {
        return;
    }

    float endTime = view_as<float>(timerDurations.Get(timerID));
    if(endTime > GetGameTime())
    {
        RequestFrame(Delay, timerID);
    }
    else
    {
        CallFunction(timerID);
        DisposeTimer(timerID);
    }
}

public any Native_Timer_UpdateFrames(Handle plugin, int numParams)
{
    int entity = GetNativeCell(1);
    if(!IsValidEntity(entity))
    {
        LogError("Entity %d is Invalid, Timer Disposed Automatically", entity);
        return -1;
    }

    int frames = GetNativeCell(2);
    if(frames <= 0)
    {
        LogError("Frames can not less than or equal 0, Timer Disposed Automatically");
        return -1;
    }

    Function func = GetNativeFunction(3);
    if(func == INVALID_FUNCTION)
    {
        char pluginName[64];
        GetPluginFilename(plugin, pluginName, 64);
        LogError("Function can not find in plugin %s, Timer Disposed Automatically", pluginName);
        return -1;
    }

    int timerID = PushIntoSequence(entity, float(frames), plugin, view_as<int>(func));
    
    UpdateFrames(timerID);
    return CreateUserHandle(timerID);
}


public any Native_Timer_UpdateFrames_WithParameters(Handle plugin, int numParams)
{
    int entity = GetNativeCell(1);
    if(!IsValidEntity(entity))
    {
        LogError("Entity %d is Invalid, Timer Disposed Automatically", entity);
        return -1;
    }

    int frames = GetNativeCell(2);
    if(frames <= 0)
    {
        LogError("Frames can not less than or equal 0, Timer Disposed Automatically");
        return -1;
    }

    Function func = GetNativeFunction(3);
    if(func == INVALID_FUNCTION)
    {
        char pluginName[64];
        GetPluginFilename(plugin, pluginName, 64);
        LogError("Function can not find in plugin %s, Timer Disposed Automatically", pluginName);
        return -1;
    }

    L4D2TimerParamPack params = view_as<L4D2TimerParamPack>(GetNativeCell(4));

    int timerID = PushIntoSequence(entity, float(frames), plugin, view_as<int>(func), params);
    
    UpdateFrames(timerID);
    return CreateUserHandle(timerID);
}

void UpdateFrames(int timerID)
{
    if(!view_as<bool>(timerFlags.Get(timerID)))
    {
        return;
    }
    else
    {
        int frames = RoundToNearest(view_as<float>(timerDurations.Get(timerID)));
        if(frames > 0)
        {

            CallFunction(timerID);
            timerDurations.Set(timerID, float(frames - 1));

            RequestFrame(UpdateFrames, timerID);
        }
        else
        {
            DisposeTimer(timerID);
        }
    }
}


public any Native_Timer_Update(Handle plugin, int numParams)
{
    int entity = GetNativeCell(1);
    if(!IsValidEntity(entity))
    {
        LogError("Entity %d is Invalid, Timer Disposed Automatically", entity);
        return -1;
    }

    float seconds = GetNativeCell(2);
    if(seconds <= 0.0)
    {
        LogError("Seconds can not less than or equal 0, Timer Disposed Automatically");
        return -1;
    }

    Function func = GetNativeFunction(3);
    if(func == INVALID_FUNCTION)
    {
        char pluginName[64];
        GetPluginFilename(plugin, pluginName, 64);
        LogError("Function can not find in plugin %s, Timer Disposed Automatically", pluginName);
        return -1;
    }

    int timerID = PushIntoSequence(entity, seconds + GetGameTime(), plugin, view_as<int>(func));
    
    Update(timerID);

    return CreateUserHandle(timerID);
}

public any Native_Timer_Update_WithParameters(Handle plugin, int numParams)
{
    int entity = GetNativeCell(1);
    if(!IsValidEntity(entity))
    {
        LogError("Entity %d is Invalid, Timer Disposed Automatically", entity);
        return -1;
    }

    float seconds = GetNativeCell(2);
    if(seconds <= 0.0)
    {
        LogError("Seconds can not less than or equal 0, Timer Disposed Automatically");
        return -1;
    }

    Function func = GetNativeFunction(3);
    if(func == INVALID_FUNCTION)
    {
        char pluginName[64];
        GetPluginFilename(plugin, pluginName, 64);
        LogError("Function can not find in plugin %s, Timer Disposed Automatically", pluginName);
        return -1;
    }
    L4D2TimerParamPack params = view_as<L4D2TimerParamPack>(GetNativeCell(4));

    int timerID = PushIntoSequence(entity, seconds + GetGameTime(), plugin, view_as<int>(func), params);
    
    Update(timerID);

    return CreateUserHandle(timerID);
}

void Update(int timerID)
{
    if(!view_as<bool>(timerFlags.Get(timerID)))
    {
        return;
    }

    float endTime = view_as<float>(timerDurations.Get(timerID));
    if(endTime > GetGameTime())
    {
        CallFunction(timerID);
        RequestFrame(Update, timerID);
    }
    else
    {
        DisposeTimer(timerID);
    }
}

public any Native_Timer_Repeat(Handle plugin, int numParams)
{
    int entity = GetNativeCell(1);
    if(!IsValidEntity(entity))
    {
        LogError("Entity %d is Invalid, Timer Disposed Automatically", entity);
        return -1;
    }

    int times = GetNativeCell(2);
    if(times <= 0)
    {
        LogError("Repeat times can not less than or equal 0, Timer Disposed Automatically");
        return -1;
    }

    float interval = GetNativeCell(3);
    if(interval <= 0.0)
    {
        LogError("Repeat interval can not less than or equal 0, Timer Disposed Automatically");
        return -1;
    }

    Function func = GetNativeFunction(4);
    if(func == INVALID_FUNCTION)
    {
        char pluginName[64];
        GetPluginFilename(plugin, pluginName, 64);
        LogError("Function can not find in plugin %s, Timer Disposed Automatically", pluginName);
        return -1;
    }

    bool callImmediately = GetNativeCell(5);

    int timerID = PushIntoSequence(entity, float(times), plugin, view_as<int>(func), INVALID_HANDLE, interval);
    
    Repeat(timerID);

    if(callImmediately)
    {
        CallFunction(timerID);
    }

    return CreateUserHandle(timerID);
}

public any Native_Timer_Repeat_WithParameters(Handle plugin, int numParams)
{
    int entity = GetNativeCell(1);
    if(!IsValidEntity(entity))
    {
        LogError("Entity %d is Invalid, Timer Disposed Automatically", entity);
        return -1;
    }

    int times = GetNativeCell(2);
    if(times <= 0)
    {
        LogError("Repeat times can not less than or equal 0, Timer Disposed Automatically");
        return -1;
    }

    float interval = GetNativeCell(3);
    if(interval <= 0.0)
    {
        LogError("Repeat interval can not less than or equal 0, Timer Disposed Automatically");
        return -1;
    }

    Function func = GetNativeFunction(4);
    if(func == INVALID_FUNCTION)
    {
        char pluginName[64];
        GetPluginFilename(plugin, pluginName, 64);
        LogError("Function can not find in plugin %s, Timer Disposed Automatically", pluginName);
        return -1;
    }
    L4D2TimerParamPack params = view_as<L4D2TimerParamPack>(GetNativeCell(5));

    bool callImmediately = GetNativeCell(6);

    int timerID = PushIntoSequence(entity, float(times), plugin, view_as<int>(func), params, interval);
    
    Repeat(timerID);

    if(callImmediately)
    {
        CallFunction(timerID);
    }
    return CreateUserHandle(timerID);
}

void Repeat(int timerID)
{
    if(!view_as<bool>(timerFlags.Get(timerID)))
    {
        return;
    }

    int leftRepeatTime = RoundToNearest(view_as<float>(timerDurations.Get(timerID)));
    if(leftRepeatTime > 0)
    {
        float nextCallTime = view_as<float>(timerNextCallTimes.Get(timerID));
        if(nextCallTime < GetGameTime())
        {
            CallFunction(timerID);
            float interval = view_as<float>(timerIntervals.Get(timerID));
            timerDurations.Set(timerID, float(leftRepeatTime - 1));
            timerNextCallTimes.Set(timerID, nextCallTime + interval);
        }
        
        RequestFrame(Repeat, timerID);
    }
    else
    {
        DisposeTimer(timerID);
    }
}

any Native_Timer_Dispose(Handle plugin, int numParams)
{
    Handle handle = GetNativeCell(1);
    if(handle == null || handle == INVALID_HANDLE)
    {
        return 0;
    }
    StringMap userHandle = view_as<StringMap>(handle);
    int timerID = 0;
    float createTime = 0.0;
    // char uuid[37];
    if(userHandle.GetValue("timerID", timerID) && userHandle.GetValue("createTime", createTime))
    {
        if(!view_as<bool>(timerFlags.Get(timerID)))
            return 0;
        
        float nowCreateTime = view_as<float>(timerCreateTimes.Get(timerID));
        if(nowCreateTime == createTime)
        {
            DisposeTimer(timerID);
        }
    }
    return 0;
}

void CallFunction(int timerID)
{
    Function func = view_as<Function>(timerFunctions.Get(timerID));            
    Handle plugin = view_as<Handle>(timerPlugins.Get(timerID));
    L4D2TimerParamPack parameters = view_as<L4D2TimerParamPack>(timerParameters.Get(timerID));

    int result = 0;
    Call_StartFunction(plugin, func);
    Call_PushCell(view_as<int>(timerCallers.Get(timerID)));
    if(parameters != INVALID_HANDLE)
    {
        Call_PushCell(parameters);
    }
    if(Call_Finish(result) == SP_ERROR_NONE)
    {
        
    }
    else
    {
        LogError("Function can not be called, maybe there are some wrong.");
    }
}

void DisposeTimer(int timerID)
{
    timerFlags.Set(timerID, false);
    L4D2TimerParamPack parameters = view_as<L4D2TimerParamPack>(timerParameters.Get(timerID));
    if(parameters != INVALID_HANDLE)
    {
        parameters.FreeParameters();
        CloseHandle(parameters);
    }

    timerParameters.Set(timerID, INVALID_HANDLE);
    idCache.Push(timerID);
}

public void OnPluginStart()
{
    idCache = new ArrayStack();
    timerUserHandles = new ArrayList();
    timerCallers = new ArrayList();
    timerDurations = new ArrayList();
    timerIntervals = new ArrayList();
    timerNextCallTimes = new ArrayList();
    timerPlugins = new ArrayList();
    timerFunctions = new ArrayList();
    timerParameters = new ArrayList();
    timerCreateTimes = new ArrayList();
    timerFlags = new ArrayList();

    HookEvent("round_end", OnAnyEnd);
    HookEvent("finale_win", OnAnyEnd);
    HookEvent("mission_lost", OnAnyEnd);
    HookEvent("map_transition", OnAnyEnd);
}


public void OnAnyEnd(Event event, const char[] name, bool dontBroadcast)
{
    // Dispose all timer
    for(int i = 0; i < timerFlags.Length; i++)
    {
        if(view_as<bool>(timerFlags.Get(i)))
        {
            DisposeTimer(i);
        }
    }

    for(int i = 0; i < timerUserHandles.Length; i++)
    {
        StringMap h = view_as<StringMap>(timerUserHandles.Get(i));
        if(h != null && h != INVALID_HANDLE)
        {
            CloseHandle(h);
        }
    }

    for(int i = 0; i < timerParameters.Length; i++)
    {
        L4D2TimerParamPack h = view_as<L4D2TimerParamPack>(timerParameters.Get(i));
        if(h != INVALID_HANDLE)
        {
            h.FreeParameters();
            CloseHandle(h);
        }
    }
    idCache.Clear();
    timerUserHandles.Clear();
    timerCallers.Clear();
    timerDurations.Clear();
    timerIntervals.Clear();
    timerNextCallTimes.Clear();
    timerPlugins.Clear();
    timerFunctions.Clear();
    timerParameters.Clear();
    timerCreateTimes.Clear();
    timerFlags.Clear();

}

int GetTimerID()
{
    if(idCache.Empty)
    {
        return timerFlags.Length;
    }
    return view_as<int>(idCache.Pop());
}


int PushIntoSequence(int entity, float time, Handle plugin, int func, L4D2TimerParamPack params = INVALID_HANDLE, float interval = 0.0)
{
    int timerID = GetTimerID();

    if(timerID >= timerFlags.Length)
    {
        timerCallers.Push(entity);
        timerDurations.Push(time);
        timerIntervals.Push(interval);
        timerNextCallTimes.Push(GetGameTime() + interval);
        timerPlugins.Push(plugin);
        timerFunctions.Push(func);
        timerParameters.Push(params);
        timerCreateTimes.Push(GetGameTime());
        timerFlags.Push(true);
    }
    else
    {
        timerCallers.Set(timerID, entity);
        timerDurations.Set(timerID, time);
        timerIntervals.Set(timerID, interval);
        timerNextCallTimes.Set(timerID, GetGameTime() + interval);
        timerPlugins.Set(timerID, plugin);
        timerFunctions.Set(timerID, func);
        timerParameters.Set(timerID, params);
        timerCreateTimes.Set(timerID, GetGameTime());
        timerFlags.Set(timerID, true);
    }
    
    return timerID;
}

Handle CreateUserHandle(int timerID)
{
    StringMap userHandle = new StringMap();
    userHandle.SetValue("timerID", timerID);
    // userHandle.SetString("uuid", GetUUIDv4());
    userHandle.SetValue("createTime", GetGameTime());
    timerUserHandles.Push(userHandle);
    return view_as<Handle>(userHandle);
}

stock char[] GetUUIDv4()
{
    char uuid[37];
    int random[4];
    
    for(int i = 0; i < 4; i++)
    {
        random[i] = GetURandomInt();
    }
    
    // Set the version position (The 13th digit is set to 4)
    random[1] = (random[1] & 0xFFFF0FFF) | 0x00004000;
    // Set the variable position (The top two digits of the 17th character are set to 01)
    random[2] = (random[2] & 0x3FFFFFFF) | 0x80000000;
    
    Format(uuid, sizeof(uuid),
        "%08x-%04x-%04x-%04x-%04x%08x",
        random[0],
        random[1] >> 16,
        random[1] & 0xFFFF,
        random[2] >> 16,
        random[2] & 0xFFFF,
        random[3]);
    
    return uuid;
}