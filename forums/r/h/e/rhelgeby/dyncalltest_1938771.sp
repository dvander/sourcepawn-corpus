#include <sourcemod>
#include <profiler>

functag public CallbackA();
functag public CallbackB(param1, param2, param3);
functag public CallbackC(const String:value[]);

#define ITERATIONS 10000000

/*
Testing with 50,000,000 iterations.
Simple total:            0.533999
Simple iteration:        0.0000000106798
DynamicSimple total:     13.456000
DynamicSimple iteration: 0.00000026912
Cell total:              0.522000
Cell iteration:          0.00000001044
DynamicCell total:       19.958000
DynamicCell iteration:   0.00000039916
String total:            0.474999
String iteration:        0.0000000094998
DynamicString total:     21.096000
DynamicString iteration: 0.00000042192

Testing with 10,000,000 iterations.
Simple total:            0.168999
Simple iteration:        0.000000
DynamicSimple total:     2.667999
DynamicSimple iteration: 0.000000
Cell total:              0.104000
Cell iteration:          0.000000
DynamicCell total:       4.021999
DynamicCell iteration:   0.000000
String total:            0.094999
String iteration:        0.000000
DynamicString total:     4.230000
DynamicString iteration: 0.000000

Testing with 1,000,000 iterations.
Simple total:            0.020999
Simple iteration:        0.000000
DynamicSimple total:     0.388999
DynamicSimple iteration: 0.000000
Cell total:              0.012000
Cell iteration:          0.000000
DynamicCell total:       0.400999
DynamicCell iteration:   0.000000
String total:            0.008999
String iteration:        0.000000
DynamicString total:     0.423000
DynamicString iteration: 0.000000
*/

public OnPluginStart()
{
    new Handle:profiler = CreateProfiler();
    
    PrintToServer("Testing with %d iterations.", ITERATIONS);
    
    Simple(profiler);
    DynamicSimple(TestCallbackA, profiler);
    Cell(profiler);
    DynamicCell(TestCallbackB, profiler);
    String(profiler);
    DynamicString(TestCallbackC, profiler);
    
    CloseHandle(profiler);
}

DynamicSimple(CallbackA:func, Handle:profiler)
{
    new Handle:plugin = GetMyHandle();
    
    StartProfiling(profiler);
    for (new i = 0; i < ITERATIONS; i++)
    {
        Call_StartFunction(plugin, func);
        Call_Finish();
    }
    StopProfiling(profiler);
    
    PrintToServer("DynamicSimple total:     %f", GetProfilerTime(profiler));
    PrintToServer("DynamicSimple iteration: %f", GetProfilerTime(profiler) / float(ITERATIONS));
}

DynamicCell(CallbackB:func, Handle:profiler)
{
    new Handle:plugin = GetMyHandle();
    new var1 = 1;
    new var2 = 2;
    new var3 = 3;
    
    StartProfiling(profiler);
    for (new i = 0; i < ITERATIONS; i++)
    {
        Call_StartFunction(plugin, func);
        Call_PushCell(var1);
        Call_PushCell(var2);
        Call_PushCell(var3);
        Call_Finish();
    }
    StopProfiling(profiler);
    
    PrintToServer("DynamicCell total:       %f", GetProfilerTime(profiler));
    PrintToServer("DynamicCell iteration:   %f", GetProfilerTime(profiler) / float(ITERATIONS));
}

DynamicString(CallbackC:func, Handle:profiler)
{
    new Handle:plugin = GetMyHandle();
    new String:var1[64] = "test test test test test test test";
    
    StartProfiling(profiler);
    for (new i = 0; i < ITERATIONS; i++)
    {
        Call_StartFunction(plugin, func);
        Call_PushString(var1);
        Call_Finish();
    }
    StopProfiling(profiler);
    
    PrintToServer("DynamicString total:     %f", GetProfilerTime(profiler));
    PrintToServer("DynamicString iteration: %f", GetProfilerTime(profiler) / float(ITERATIONS));
}

Simple(Handle:profiler)
{
    StartProfiling(profiler);
    for (new i = 0; i < ITERATIONS; i++)
    {
        TestCallbackA();
    }
    StopProfiling(profiler);
    
    PrintToServer("Simple total:            %f", GetProfilerTime(profiler));
    PrintToServer("Simple iteration:        %f", GetProfilerTime(profiler) / float(ITERATIONS));
}

Cell(Handle:profiler)
{
    new var1 = 1;
    new var2 = 2;
    new var3 = 3;
    
    StartProfiling(profiler);
    for (new i = 0; i < ITERATIONS; i++)
    {
        TestCallbackB(var1, var2, var3);
    }
    StopProfiling(profiler);
    
    PrintToServer("Cell total:              %f", GetProfilerTime(profiler));
    PrintToServer("Cell iteration:          %f", GetProfilerTime(profiler) / float(ITERATIONS));
}

String(Handle:profiler)
{
    new String:var1[64] = "test test test test test test test";
    
    StartProfiling(profiler);
    for (new i = 0; i < ITERATIONS; i++)
    {
        TestCallbackC(var1);
    }
    StopProfiling(profiler);
    
    PrintToServer("String total:            %f", GetProfilerTime(profiler));
    PrintToServer("String iteration:        %f", GetProfilerTime(profiler) / float(ITERATIONS));
}

// Test callbacks (does nothing).
public TestCallbackA() {}
public TestCallbackB(param1, param2, param3) {}
public TestCallbackC(const String:value[]) {}
