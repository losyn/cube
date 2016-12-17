-- Created by losyn on 12/8/16
return {
    init = function(tcx)
        tcx.log("init complete")
    end,

    test0001 = function(tcx)
        error("test0001 not invalid")
    end,

    test0002 = function(tcx)
        tcx.log("test0001 not invalid")
    end
}
