#TIME NODE(S)   DEVICE  MODE    ELEMENT HANDLER  VALUE
100    FIRSTNODE DEV0    write   sf      add_flow FIRSTNODE:eth FF-FF-FF-FF-FF-FF 1000 100 0 11000 true
#100    FIRSTNODE DEV0    write  unicastsf      add_flow FIRSTNODE:eth LASTNODE:eth 0 1500 0 100000 true
#115    FIRSTNODE DEV0    write  sf      add_flow FIRSTNODE:eth 00-00-00-00-00-03 15 120 0 6000 true
#115    FIRSTNODE DEV0    write  sf      add_flow FIRSTNODE:eth FF-FF-FF-FF-FF-FF 500 120 0 20600 true
#175    sk22      DEV0    read   flooding/fl stats
#175    sk22      DEV0    read   flooding/fl forward_table
#175    sk22      DEV0    read   flooding/unicfl stats
#175    sk22      DEV0    read   flooding/fl_passive_ack stats
#175    sk16      DEV0    read   flooding/fl stats
#175    sk16      DEV0    read   flooding/fl forward_table
#175    sk16      DEV0    read   flooding/unicfl stats
#175    sk16      DEV0    read   flooding/fl_passive_ack stats
#175    sk17      DEV0    read   flooding/fl stats
#175    sk17      DEV0    read   flooding/fl forward_table
#175    sk17      DEV0    read   flooding/unicfl stats
#175    sk17      DEV0    read   flooding/fl_passive_ack stats
#175    sk21      DEV0    read   flooding/fl stats
#175    sk21      DEV0    read   flooding/fl forward_table
#175    sk21      DEV0    read   flooding/unicfl stats
#175    sk21      DEV0    read   flooding/fl_passive_ack stats
199     FIRSTNODE DEV0    read   unicastsf stats
199     LASTNODE  DEV0    read   unicastsf stats