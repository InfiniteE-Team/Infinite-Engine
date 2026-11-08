package core.api;

#if (cpp && windows)
@:cppInclude("windows.h")
@:cppInclude("psapi.h")
#elseif (cpp && mac)
@:cppInclude("mach/mach.h")
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
        #elseif (cpp && mac)
        var memUsage:Float = 0.0;
        untyped __cpp__('
            mach_task_basic_info_data_t info;
            mach_msg_type_number_t count = MACH_TASK_BASIC_INFO_COUNT;
            if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &count) == KERN_SUCCESS) {
                {0} = (double)info.resident_size / (1024.0 * 1024.0);
            }
        ', memUsage);
        return memUsage;
        #else
        return openfl.system.System.totalMemory / (1024.0 * 1024.0);
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