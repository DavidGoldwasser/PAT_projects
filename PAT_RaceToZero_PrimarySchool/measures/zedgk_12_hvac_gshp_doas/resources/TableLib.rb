module TableLib

  # do something
  def TableLib.doSomething(input)

    # do something
    output = input

    result = output
    return result

  end

  # tables with two independent variables

  # tableDataPartLoadHtgCapfTemp
  def TableLib.tableDataPartLoadHtgCapfTemp()

    # raw table data
    n = []
    n << [0,'PartLoadHtgCapfTemp']
    n << [1,'Biquadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,0]
    n << [6,100]
    n << [7,'']
    n << [8,'']
    n << [9,'Temperature']
    n << [10,'Temperature']
    n << [11,'Power']
    n << [12,8.41114057]
    n << [13,15.5555555555556]
    n << [14,-1.11111111111111]
    n << [15,3.98576696]
    n << [16,21.1111111111111]
    n << [17,-1.11111111111111]
    n << [18,3.86853852]
    n << [19,26.6666666666667]
    n << [20,-1.11111111111111]
    n << [21,3.72200297]
    n << [22,15.5555555555556]
    n << [23,4.44444444444444]
    n << [24,5.2752798]
    n << [25,21.1111111111111]
    n << [26,4.44444444444444]
    n << [27,5.07013003]
    n << [28,26.6666666666667]
    n << [29,4.44444444444444]
    n << [30,4.89428737]
    n << [31,15.5555555555556]
    n << [32,10]
    n << [33,6.47687131]
    n << [34,21.1111111111111]
    n << [35,10]
    n << [36,6.24241443]
    n << [37,26.6666666666667]
    n << [38,10]
    n << [39,6.03726466]
    n << [40,15.5555555555556]
    n << [41,15.5555555555556]
    n << [42,7.6198486]
    n << [43,21.1111111111111]
    n << [44,15.5555555555556]
    n << [45,7.35608461]
    n << [46,26.6666666666667]
    n << [47,15.5555555555556]
    n << [48,7.09232062]
    n << [49,15.5555555555556]
    n << [50,21.1111111111111]
    n << [51,8.70421167]
    n << [52,21.1111111111111]
    n << [53,21.1111111111111]
    n << [54,8.41114057]
    n << [55,26.6666666666667]
    n << [56,21.1111111111111]
    n << [57,8.11806947]
    n << [58,15.5555555555556]
    n << [59,26.6666666666667]
    n << [60,9.75926763]
    n << [61,21.1111111111111]
    n << [62,26.6666666666667]
    n << [63,9.40758231]
    n << [64,26.6666666666667]
    n << [65,26.6666666666667]
    n << [66,9.0852041]
    n << [67,15.5555555555556]
    n << [68,32.2222222222222]
    n << [69,10.72640226]
    n << [70,21.1111111111111]
    n << [71,32.2222222222222]
    n << [72,10.34540983]
    n << [73,26.6666666666667]
    n << [74,32.2222222222222]
    n << [75,9.99372451]

    table_data = {}
    table_data['unit_types'] = [n[9][1],n[10][1],n[11][1]]
    table_data['norm_ref'] = n[12][1]
    table_data['xyz_data'] = []
    counter = 12
    until counter == n.size - 1
      counter += 1
      next if !((counter-13)%3).zero? # only process every three
      table_data['xyz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1],n[counter+2].to_a[1]]
    end
    return table_data
  end

  # tableDataPartLoadHtgEIRfTemp
  def TableLib.tableDataPartLoadHtgEIRfTemp()

    # raw table data
    n = []
    n << [0,'PartLoadHtgEIRfTemp']
    n << [1,'Biquadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,0]
    n << [6,100]
    n << [7,'']
    n << [8,'']
    n << [9,'Temperature']
    n << [10,'Temperature']
    n << [11,'Dimensionless']
    n << [12,0.172711572]
    n << [13,15.5555555555556]
    n << [14,-1.11111111111111]
    n << [15,0.232558139534884]
    n << [16,21.1111111111111]
    n << [17,-1.11111111111111]
    n << [18,0.25]
    n << [19,26.6666666666667]
    n << [20,-1.11111111111111]
    n << [21,0.274725274725275]
    n << [22,15.5555555555556]
    n << [23,4.44444444444444]
    n << [24,0.208333333333333]
    n << [25,21.1111111111111]
    n << [26,4.44444444444444]
    n << [27,0.224215246636771]
    n << [28,26.6666666666667]
    n << [29,4.44444444444444]
    n << [30,0.246305418719212]
    n << [31,15.5555555555556]
    n << [32,10]
    n << [33,0.189035916824197]
    n << [34,21.1111111111111]
    n << [35,10]
    n << [36,0.203665987780041]
    n << [37,26.6666666666667]
    n << [38,10]
    n << [39,0.223713646532438]
    n << [40,15.5555555555556]
    n << [41,15.5555555555556]
    n << [42,0.173611111111111]
    n << [43,21.1111111111111]
    n << [44,15.5555555555556]
    n << [45,0.186567164179104]
    n << [46,26.6666666666667]
    n << [47,15.5555555555556]
    n << [48,0.205338809034908]
    n << [49,15.5555555555556]
    n << [50,21.1111111111111]
    n << [51,0.160513643659711]
    n << [52,21.1111111111111]
    n << [53,21.1111111111111]
    n << [54,0.172711571675302]
    n << [55,26.6666666666667]
    n << [56,21.1111111111111]
    n << [57,0.189753320683112]
    n << [58,15.5555555555556]
    n << [59,26.6666666666667]
    n << [60,0.149700598802395]
    n << [61,21.1111111111111]
    n << [62,26.6666666666667]
    n << [63,0.161030595813205]
    n << [64,26.6666666666667]
    n << [65,26.6666666666667]
    n << [66,0.176991150442478]
    n << [67,15.5555555555556]
    n << [68,32.2222222222222]
    n << [69,0.140252454417952]
    n << [70,21.1111111111111]
    n << [71,32.2222222222222]
    n << [72,0.151057401812689]
    n << [73,26.6666666666667]
    n << [74,32.2222222222222]
    n << [75,0.165837479270315]


    table_data = {}
    table_data['unit_types'] = [n[9][1],n[10][1],n[11][1]]
    table_data['norm_ref'] = n[12][1]
    table_data['xyz_data'] = []
    counter = 12
    until counter == n.size - 1
      counter += 1
      next if !((counter-13)%3).zero? # only process every three
      table_data['xyz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1],n[counter+2].to_a[1]]
    end
    return table_data
  end

  # tableDataFullLoadHtgCapfTemp
  def TableLib.tableDataFullLoadHtgCapfTemp()

    # raw table data
    n = []
    n << [0,'FullLoadHtgCapfTemp']
    n << [1,'Biquadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,0]
    n << [6,100]
    n << [7,'']
    n << [8,'']
    n << [9,'Temperature']
    n << [10,'Temperature']
    n << [11,'Power']
    n << [12,11.1367018]
    n << [13,15.5555555555556]
    n << [14,-1.11111111111111]
    n << [15,5.65627223]
    n << [16,21.1111111111111]
    n << [17,-1.11111111111111]
    n << [18,5.45112246]
    n << [19,26.6666666666667]
    n << [20,-1.11111111111111]
    n << [21,5.24597269]
    n << [22,15.5555555555556]
    n << [23,4.44444444444444]
    n << [24,7.12162773]
    n << [25,21.1111111111111]
    n << [26,4.44444444444444]
    n << [27,6.88717085]
    n << [28,26.6666666666667]
    n << [29,4.44444444444444]
    n << [30,6.62340686]
    n << [31,15.5555555555556]
    n << [32,10]
    n << [33,8.58698323]
    n << [34,21.1111111111111]
    n << [35,10]
    n << [36,8.29391213]
    n << [37,26.6666666666667]
    n << [38,10]
    n << [39,8.00084103]
    n << [40,15.5555555555556]
    n << [41,15.5555555555556]
    n << [42,10.08164584]
    n << [43,21.1111111111111]
    n << [44,15.5555555555556]
    n << [45,9.72996052]
    n << [46,26.6666666666667]
    n << [47,15.5555555555556]
    n << [48,9.3782752]
    n << [49,15.5555555555556]
    n << [50,21.1111111111111]
    n << [51,11.54700134]
    n << [52,21.1111111111111]
    n << [53,21.1111111111111]
    n << [54,11.1367018]
    n << [55,26.6666666666667]
    n << [56,21.1111111111111]
    n << [57,10.75570937]
    n << [58,15.5555555555556]
    n << [59,26.6666666666667]
    n << [60,13.01235684]
    n << [61,21.1111111111111]
    n << [62,26.6666666666667]
    n << [63,12.57275019]
    n << [64,26.6666666666667]
    n << [65,26.6666666666667]
    n << [66,12.10383643]
    n << [67,15.5555555555556]
    n << [68,32.2222222222222]
    n << [69,14.47771234]
    n << [70,21.1111111111111]
    n << [71,32.2222222222222]
    n << [72,13.97949147]
    n << [73,26.6666666666667]
    n << [74,32.2222222222222]
    n << [75,13.4812706]

    table_data = {}
    table_data['unit_types'] = [n[9][1],n[10][1],n[11][1]]
    table_data['norm_ref'] = n[12][1]
    table_data['xyz_data'] = []
    counter = 12
    until counter == n.size - 1
      counter += 1
      next if !((counter-13)%3).zero? # only process every three
      table_data['xyz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1],n[counter+2].to_a[1]]
    end
    return table_data
  end

  # tableDataFullLoadHtgEIRfTemp
  def TableLib.tableDataFullLoadHtgEIRfTemp()

    # raw table data
    n = []
    n << [0,'FullLoadHtgEIRfTemp']
    n << [1,'Biquadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,0]
    n << [6,100]
    n << [7,'']
    n << [8,'']
    n << [9,'Temperature']
    n << [10,'Temperature']
    n << [11,'Dimensionless']
    n << [12,0.192678227]
    n << [13,15.5555555555556]
    n << [14,-1.11111111111111]
    n << [15,0.273972602739726]
    n << [16,21.1111111111111]
    n << [17,-1.11111111111111]
    n << [18,0.294117647058824]
    n << [19,26.6666666666667]
    n << [20,-1.11111111111111]
    n << [21,0.323624595469256]
    n << [22,15.5555555555556]
    n << [23,4.44444444444444]
    n << [24,0.240963855421687]
    n << [25,21.1111111111111]
    n << [26,4.44444444444444]
    n << [27,0.259067357512953]
    n << [28,26.6666666666667]
    n << [29,4.44444444444444]
    n << [30,0.284900284900285]
    n << [31,15.5555555555556]
    n << [32,10]
    n << [33,0.21551724137931]
    n << [34,21.1111111111111]
    n << [35,10]
    n << [36,0.232018561484919]
    n << [37,26.6666666666667]
    n << [38,10]
    n << [39,0.255102040816327]
    n << [40,15.5555555555556]
    n << [41,15.5555555555556]
    n << [42,0.195694716242661]
    n << [43,21.1111111111111]
    n << [44,15.5555555555556]
    n << [45,0.210526315789474]
    n << [46,26.6666666666667]
    n << [47,15.5555555555556]
    n << [48,0.23094688221709]
    n << [49,15.5555555555556]
    n << [50,21.1111111111111]
    n << [51,0.17921146953405]
    n << [52,21.1111111111111]
    n << [53,21.1111111111111]
    n << [54,0.192678227360308]
    n << [55,26.6666666666667]
    n << [56,21.1111111111111]
    n << [57,0.211864406779661]
    n << [58,15.5555555555556]
    n << [59,26.6666666666667]
    n << [60,0.165837479270315]
    n << [61,21.1111111111111]
    n << [62,26.6666666666667]
    n << [63,0.17825311942959]
    n << [64,26.6666666666667]
    n << [65,26.6666666666667]
    n << [66,0.196078431372549]
    n << [67,15.5555555555556]
    n << [68,32.2222222222222]
    n << [69,0.154320987654321]
    n << [70,21.1111111111111]
    n << [71,32.2222222222222]
    n << [72,0.166112956810631]
    n << [73,26.6666666666667]
    n << [74,32.2222222222222]
    n << [75,0.182481751824818]

    table_data = {}
    table_data['unit_types'] = [n[9][1],n[10][1],n[11][1]]
    table_data['norm_ref'] = n[12][1]
    table_data['xyz_data'] = []
    counter = 12
    until counter == n.size - 1
      counter += 1
      next if !((counter-13)%3).zero? # only process every three
      table_data['xyz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1],n[counter+2].to_a[1]]
    end
    return table_data
  end

  # tableDataPartLoadHClgCapfTemp
  def TableLib.tableDataPartLoadClgCapfTemp()

    # raw table data
    n = []
    n << [0,'PartLoadClgCapfTemp']
    n << [1,'Biquadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,0]
    n << [6,100]
    n << [7,'']
    n << [8,'']
    n << [9,'Temperature']
    n << [10,'Temperature']
    n << [11,'Power']
    n << [12,5.758847115]
    n << [13,17.2222222222222]
    n << [14,10]
    n << [15,5.71488645]
    n << [16,19.4444444444444]
    n << [17,10]
    n << [18,6.27172154]
    n << [19,21.6666666666667]
    n << [20,10]
    n << [21,6.79924952]
    n << [22,17.2222222222222]
    n << [23,15.5555555555556]
    n << [24,5.62696512]
    n << [25,19.4444444444444]
    n << [26,15.5555555555556]
    n << [27,6.1544931]
    n << [28,21.6666666666667]
    n << [29,15.5555555555556]
    n << [30,6.71132819]
    n << [31,17.2222222222222]
    n << [32,21.1111111111111]
    n << [33,5.50973668]
    n << [34,19.4444444444444]
    n << [35,21.1111111111111]
    n << [36,6.03726466]
    n << [37,21.6666666666667]
    n << [38,21.1111111111111]
    n << [39,6.56479264]
    n << [40,17.2222222222222]
    n << [41,26.6666666666667]
    n << [42,5.36320113]
    n << [43,19.4444444444444]
    n << [44,26.6666666666667]
    n << [45,5.861422]
    n << [46,21.6666666666667]
    n << [47,26.6666666666667]
    n << [48,6.38894998]
    n << [49,17.2222222222222]
    n << [50,32.2222222222222]
    n << [51,5.15805136]
    n << [52,19.4444444444444]
    n << [53,32.2222222222222]
    n << [54,5.65627223]
    n << [55,21.6666666666667]
    n << [56,32.2222222222222]
    n << [57,6.1544931]
    n << [58,17.2222222222222]
    n << [59,37.7777777777778]
    n << [60,4.95290159]
    n << [61,19.4444444444444]
    n << [62,37.7777777777778]
    n << [63,5.42181535]
    n << [64,21.6666666666667]
    n << [65,37.7777777777778]
    n << [66,5.89072911]
    n << [67,17.2222222222222]
    n << [68,43.3333333333333]
    n << [69,4.6891376]
    n << [70,19.4444444444444]
    n << [71,43.3333333333333]
    n << [72,5.12874425]
    n << [73,21.6666666666667]
    n << [74,43.3333333333333]
    n << [75,5.59765801]

    table_data = {}
    table_data['unit_types'] = [n[9][1],n[10][1],n[11][1]]
    table_data['norm_ref'] = n[12][1]
    table_data['xyz_data'] = []
    counter = 12
    until counter == n.size - 1
      counter += 1
      next if !((counter-13)%3).zero? # only process every three
      table_data['xyz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1],n[counter+2].to_a[1]]
    end
    return table_data
  end

  # tableDataPartLoadClgEIRfTemp
  def TableLib.tableDataPartLoadClgEIRfTemp()

    # raw table data
    n = []
    n << [0,'PartLoadClgEIRfTemp']
    n << [1,'Biquadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,0]
    n << [6,100]
    n << [7,'']
    n << [8,'']
    n << [9,'Temperature']
    n << [10,'Temperature']
    n << [11,'Dimensionless']
    n << [12,0.081746507]
    n << [13,17.2222222222222]
    n << [14,10]
    n << [15,0.0564594715558431]
    n << [16,19.4444444444444]
    n << [17,10]
    n << [18,0.0519256952436662]
    n << [19,21.6666666666667]
    n << [20,10]
    n << [21,0.0480793474478391]
    n << [22,17.2222222222222]
    n << [23,15.5555555555556]
    n << [24,0.0633549316065157]
    n << [25,19.4444444444444]
    n << [26,15.5555555555556]
    n << [27,0.0582674399906386]
    n << [28,21.6666666666667]
    n << [29,15.5555555555556]
    n << [30,0.0539513333246654]
    n << [31,17.2222222222222]
    n << [32,21.1111111111111]
    n << [33,0.0717669605941961]
    n << [34,19.4444444444444]
    n << [35,21.1111111111111]
    n << [36,0.0660039710200363]
    n << [37,21.6666666666667]
    n << [38,21.1111111111111]
    n << [39,0.0611147879815151]
    n << [40,17.2222222222222]
    n << [41,26.6666666666667]
    n << [42,0.0822266133616481]
    n << [43,19.4444444444444]
    n << [44,26.6666666666667]
    n << [45,0.0756236987112544]
    n << [46,21.6666666666667]
    n << [47,26.6666666666667]
    n << [48,0.0700219432511614]
    n << [49,17.2222222222222]
    n << [50,32.2222222222222]
    n << [51,0.0955414296167481]
    n << [52,19.4444444444444]
    n << [53,32.2222222222222]
    n << [54,0.0878693161787133]
    n << [55,21.6666666666667]
    n << [56,32.2222222222222]
    n << [57,0.0813604779432531]
    n << [58,17.2222222222222]
    n << [59,37.7777777777778]
    n << [60,0.113001486198756]
    n << [61,19.4444444444444]
    n << [62,37.7777777777778]
    n << [63,0.103927305246461]
    n << [64,21.6666666666667]
    n << [65,37.7777777777778]
    n << [66,0.0962289863393154]
    n << [67,17.2222222222222]
    n << [68,43.3333333333333]
    n << [69,0.136801799221149]
    n << [70,19.4444444444444]
    n << [71,43.3333333333333]
    n << [72,0.12581641909483]
    n << [73,21.6666666666667]
    n << [74,43.3333333333333]
    n << [75,0.116496684347065]

    table_data = {}
    table_data['unit_types'] = [n[9][1],n[10][1],n[11][1]]
    table_data['norm_ref'] = n[12][1]
    table_data['xyz_data'] = []
    counter = 12
    until counter == n.size - 1
      counter += 1
      next if !((counter-13)%3).zero? # only process every three
      table_data['xyz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1],n[counter+2].to_a[1]]
    end
    return table_data
  end

  # tableDataFullLoadClgCapfTemp
  def TableLib.tableDataFullLoadClgCapfTemp()

    # raw table data
    n = []
    n << [0,'FullLoadClgCapfTemp']
    n << [1,'Biquadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,0]
    n << [6,100]
    n << [7,'']
    n << [8,'']
    n << [9,'Temperature']
    n << [10,'Temperature']
    n << [11,'Power']
    n << [12,8.630943895]
    n << [13,17.2222222222222]
    n << [14,10]
    n << [15,9.49550364]
    n << [16,19.4444444444444]
    n << [17,10]
    n << [18,10.43333116]
    n << [19,21.6666666666667]
    n << [20,10]
    n << [21,11.34185157]
    n << [22,17.2222222222222]
    n << [23,15.5555555555556]
    n << [24,9.14381832]
    n << [25,19.4444444444444]
    n << [26,15.5555555555556]
    n << [27,10.02303162]
    n << [28,21.6666666666667]
    n << [29,15.5555555555556]
    n << [30,10.90224492]
    n << [31,17.2222222222222]
    n << [32,21.1111111111111]
    n << [33,8.70421167]
    n << [34,19.4444444444444]
    n << [35,21.1111111111111]
    n << [36,9.55411786]
    n << [37,21.6666666666667]
    n << [38,21.1111111111111]
    n << [39,10.37471694]
    n << [40,17.2222222222222]
    n << [41,26.6666666666667]
    n << [42,8.17668369]
    n << [43,19.4444444444444]
    n << [44,26.6666666666667]
    n << [45,8.96797566]
    n << [46,21.6666666666667]
    n << [47,26.6666666666667]
    n << [48,9.75926763]
    n << [49,17.2222222222222]
    n << [50,32.2222222222222]
    n << [51,7.56123438]
    n << [52,19.4444444444444]
    n << [53,32.2222222222222]
    n << [54,8.29391213]
    n << [55,21.6666666666667]
    n << [56,32.2222222222222]
    n << [57,9.02658988]
    n << [58,17.2222222222222]
    n << [59,37.7777777777778]
    n << [60,6.88717085]
    n << [61,19.4444444444444]
    n << [62,37.7777777777778]
    n << [63,7.53192727]
    n << [64,21.6666666666667]
    n << [65,37.7777777777778]
    n << [66,8.2059908]
    n << [67,17.2222222222222]
    n << [68,43.3333333333333]
    n << [69,6.09587888]
    n << [70,19.4444444444444]
    n << [71,43.3333333333333]
    n << [72,6.68202108]
    n << [73,21.6666666666667]
    n << [74,43.3333333333333]
    n << [75,7.26816328]

    table_data = {}
    table_data['unit_types'] = [n[9][1],n[10][1],n[11][1]]
    table_data['norm_ref'] = n[12][1]
    table_data['xyz_data'] = []
    counter = 12
    until counter == n.size - 1
      counter += 1
      next if !((counter-13)%3).zero? # only process every three
      table_data['xyz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1],n[counter+2].to_a[1]]
    end
    return table_data
  end

  # tableDataFullLoadClgEIRfTemp
  def TableLib.tableDataFullLoadClgEIRfTemp()

    # raw table data
    n = []
    n << [0,'FullLoadClgEIRfTemp']
    n << [1,'Biquadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,0]
    n << [6,100]
    n << [7,'']
    n << [8,'']
    n << [9,'Temperature']
    n << [10,'Temperature']
    n << [11,'Dimensionless']
    n << [12,0.210649727]
    n << [13,17.2222222222222]
    n << [14,10]
    n << [15,0.120188139691856]
    n << [16,19.4444444444444]
    n << [17,10]
    n << [18,0.110568414966034]
    n << [19,21.6666666666667]
    n << [20,10]
    n << [21,0.102374476023156]
    n << [22,17.2222222222222]
    n << [23,15.5555555555556]
    n << [24,0.143548224057711]
    n << [25,19.4444444444444]
    n << [26,15.5555555555556]
    n << [27,0.131997728659644]
    n << [28,21.6666666666667]
    n << [29,15.5555555555556]
    n << [30,0.122255151768248]
    n << [31,17.2222222222222]
    n << [32,21.1111111111111]
    n << [33,0.17250461505823]
    n << [34,19.4444444444444]
    n << [35,21.1111111111111]
    n << [36,0.158704245853572]
    n << [37,21.6666666666667]
    n << [38,21.1111111111111]
    n << [39,0.146948375790344]
    n << [40,17.2222222222222]
    n << [41,26.6666666666667]
    n << [42,0.208057395478768]
    n << [43,19.4444444444444]
    n << [44,26.6666666666667]
    n << [45,0.191370795617038]
    n << [46,21.6666666666667]
    n << [47,26.6666666666667]
    n << [48,0.177162060532284]
    n << [49,17.2222222222222]
    n << [50,32.2222222222222]
    n << [51,0.249973720575223]
    n << [52,19.4444444444444]
    n << [53,32.2222222222222]
    n << [54,0.229928658076267]
    n << [55,21.6666666666667]
    n << [56,32.2222222222222]
    n << [57,0.212859718393749]
    n << [58,17.2222222222222]
    n << [59,37.7777777777778]
    n << [60,0.296192819952413]
    n << [61,19.4444444444444]
    n << [62,37.7777777777778]
    n << [63,0.272317740291444]
    n << [64,21.6666666666667]
    n << [65,37.7777777777778]
    n << [66,0.252190782398507]
    n << [67,17.2222222222222]
    n << [68,43.3333333333333]
    n << [69,0.34087325532985]
    n << [70,19.4444444444444]
    n << [71,43.3333333333333]
    n << [72,0.313327941767842]
    n << [73,21.6666666666667]
    n << [74,43.3333333333333]
    n << [75,0.290148068524813]

    table_data = {}
    table_data['unit_types'] = [n[9][1],n[10][1],n[11][1]]
    table_data['norm_ref'] = n[12][1]
    table_data['xyz_data'] = []
    counter = 12
    until counter == n.size - 1
      counter += 1
      next if !((counter-13)%3).zero? # only process every three
      table_data['xyz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1],n[counter+2].to_a[1]]
    end
    return table_data
  end

  # Tables with one variable

  # tableDataPartLoadHtgCapfWaterFlowFrac
  def TableLib.tableDataPartLoadHtgCapfWaterFlowFrac()

    # raw table data
    n = []
    n << [0,'PartLoadHtgCapfWaterFlowFrac']
    n << [1,'Quadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,'']
    n << [6,'']
    n << [7,'Dimensionless']
    n << [8,'Power']
    n << [9,8.41114057]
    n << [10,1]
    n << [11,8.41114057]
    n << [12,1.19047619]
    n << [13,8.82144011]

    table_data = {}
    table_data['unit_types'] = [n[7][1],n[8][1]]
    table_data['norm_ref'] = n[9][1]
    table_data['xz_data'] = []
    counter = 9
    until counter == n.size - 1
      counter += 1
      next if !((counter-10)%2).zero? # only process every two
      table_data['xz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1]]
    end
    return table_data
  end

  # tableDataPartLoadHtgEIRfWaterFlowFrac
  def TableLib.tableDataPartLoadHtgEIRfWaterFlowFrac()

    # raw table data
    n = []
    n << [0,'PartLoadHtgEIRfWaterFlowFrac']
    n << [1,'Quadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,'']
    n << [6,'']
    n << [7,'Dimensionless']
    n << [8,'Dimensionless']
    n << [9,0.172711572]
    n << [10,1]
    n << [11,0.172711572]
    n << [12,1.19047619]
    n << [13,0.170648464]

    table_data = {}
    table_data['unit_types'] = [n[7][1],n[8][1]]
    table_data['norm_ref'] = n[9][1]
    table_data['xz_data'] = []
    counter = 9
    until counter == n.size - 1
      counter += 1
      next if !((counter-10)%2).zero? # only process every two
      table_data['xz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1]]
    end
    return table_data
  end

  # tableDataFullLoadHtgCapfWaterFlowFrac
  def TableLib.tableDataFullLoadHtgCapfWaterFlowFrac()

    # raw table data
    n = []
    n << [0,'FullLoadHtgCapfWaterFlowFrac']
    n << [1,'Quadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,'']
    n << [6,'']
    n << [7,'Dimensionless']
    n << [8,'Power']
    n << [9,11.1367018]
    n << [10,1]
    n << [11,11.1367018]
    n << [12,1.19047619]
    n << [13,11.69353689]

    table_data = {}
    table_data['unit_types'] = [n[7][1],n[8][1]]
    table_data['norm_ref'] = n[9][1]
    table_data['xz_data'] = []
    counter = 9
    until counter == n.size - 1
      counter += 1
      next if !((counter-10)%2).zero? # only process every two
      table_data['xz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1]]
    end
    return table_data
  end

  # tableDataFullLoadHtgEIRfWaterFlowFrac
  def TableLib.tableDataFullLoadHtgEIRfWaterFlowFrac()

    # raw table data
    n = []
    n << [0,'FullLoadHtgEIRfWaterFlowFrac']
    n << [1,'Quadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,'']
    n << [6,'']
    n << [7,'Dimensionless']
    n << [8,'Dimensionless']
    n << [9,0.192678227]
    n << [10,1]
    n << [11,0.192678227]
    n << [12,1.19047619]
    n << [13,0.19047619]

    table_data = {}
    table_data['unit_types'] = [n[7][1],n[8][1]]
    table_data['norm_ref'] = n[9][1]
    table_data['xz_data'] = []
    counter = 9
    until counter == n.size - 1
      counter += 1
      next if !((counter-10)%2).zero? # only process every two
      table_data['xz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1]]
    end
    return table_data
  end

  # tableDataPartLoadClgCapfWaterFlowFrac
  def TableLib.tableDataPartLoadClgCapfWaterFlowFrac()

    # raw table data
    n = []
    n << [0,'PartLoadClgCapfWaterFlowFrac']
    n << [1,'Quadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,'']
    n << [6,'']
    n << [7,'Dimensionless']
    n << [8,'Power']
    n << [9,5.758847115]
    n << [10,1]
    n << [11,5.758847115]
    n << [12,1.19047619]
    n << [13,5.846768445] 

    table_data = {}
    table_data['unit_types'] = [n[7][1],n[8][1]]
    table_data['norm_ref'] = n[9][1]
    table_data['xz_data'] = []
    counter = 9
    until counter == n.size - 1
      counter += 1
      next if !((counter-10)%2).zero? # only process every two
      table_data['xz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1]]
    end
    return table_data
  end

  # tableDataPartLoadClgEIRfWaterFlowFrac
  def TableLib.tableDataPartLoadClgEIRfWaterFlowFrac()

    # raw table data
    n = []
    n << [0,'PartLoadClgEIRfWaterFlowFrac']
    n << [1,'Quadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,'']
    n << [6,'']
    n << [7,'Dimensionless']
    n << [8,'Dimensionless']
    n << [9,0.081746516]
    n << [10,1]
    n << [11,0.081746516]
    n << [12,1.19047619]
    n << [13,0.078476655]

    table_data = {}
    table_data['unit_types'] = [n[7][1],n[8][1]]
    table_data['norm_ref'] = n[9][1]
    table_data['xz_data'] = []
    counter = 9
    until counter == n.size - 1
      counter += 1
      next if !((counter-10)%2).zero? # only process every two
      table_data['xz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1]]
    end
    return table_data
  end

  # tableDataFullLoadClgCapfWaterFlowFrac
  def TableLib.tableDataFullLoadClgCapfWaterFlowFrac()

    # raw table data
    n = []
    n << [0,'FullLoadClgCapfWaterFlowFrac']
    n << [1,'Quadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,'']
    n << [6,'']
    n << [7,'Dimensionless']
    n << [8,'Power']
    n << [9,8.630943895]
    n << [10,1]
    n << [11,8.630943895]
    n << [12,1.19047619]
    n << [13,8.748172335]

    table_data = {}
    table_data['unit_types'] = [n[7][1],n[8][1]]
    table_data['norm_ref'] = n[9][1]
    table_data['xz_data'] = []
    counter = 9
    until counter == n.size - 1
      counter += 1
      next if !((counter-10)%2).zero? # only process every two
      table_data['xz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1]]
    end
    return table_data
  end

  # tableDataFullLoadClgEIRfWaterFlowFrac
  def TableLib.tableDataFullLoadClgEIRfWaterFlowFrac()

    # raw table data
    n = []
    n << [0,'FullLoadClgEIRfWaterFlowFrac']
    n << [1,'Quadratic']
    n << [2,'LagrangeInterpolationLinearExtrapolation']
    n << [3,0]
    n << [4,100]
    n << [5,'']
    n << [6,'']
    n << [7,'Dimensionless']
    n << [8,'Dimensionless']
    n << [9,0.210649748]
    n << [10,1]
    n << [11,0.210649748]
    n << [12,1.19047619]
    n << [13,0.202176841]

    table_data = {}
    table_data['unit_types'] = [n[7][1],n[8][1]]
    table_data['norm_ref'] = n[9][1]
    table_data['xz_data'] = []
    counter = 9
    until counter == n.size - 1
      counter += 1
      next if !((counter-10)%2).zero? # only process every two
      table_data['xz_data'] << [n[counter].to_a[1],n[counter+1].to_a[1]]
    end
    return table_data
  end

end