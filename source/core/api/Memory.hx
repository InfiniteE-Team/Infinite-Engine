package core.api;

#if (cpp && windows)
@:cppInclude("windows.h")
@:cppInclude("psapi.h")
#end
class Memory {
    public static function getProcessMemoryMB():Float {
        #if (cpp && windows)
        var memUsage:Float = 0.0;
        untyped __cpp__('
            PROCESS_MEMORY_COUNTERS pmc;
            if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
                {0} = (double)pmc.WorkingSetSize / (1024.0 * 1024.0);
            }
        ', memUsage);
        return memUsage;
        #else
        return openfl.system.System.totalMemory;
        #end
    }

    public static function formatRam(mb:Float):String {
        if (mb >= 1024) {
            var gb = mb / 1024.0;
            return (Math.round(gb * 100) / 100) + ' GB';
        }
        return (Math.round(mb * 100) / 100) + ' MB';
    }
}