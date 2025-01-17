cd output/mapping

# F03, F06, F15 only: `LOT_DIVISION` after `SHORT_DESCR`
for i in F03 F06 F15
    ex -c (grep -n /LOT_DIVISION {$i}*.csv | cut -d: -f1)m(grep -n OBJECT_CONTRACT/SHORT_DESCR {$i}*.csv | cut -d: -f1) -c w -c q {$i}*.csv
end

# F25 only: `LOT_DIVISION` after `CALCULATION_METHOD`
for i in F25
    ex -c (grep -n /LOT_DIVISION {$i}*.csv | cut -d: -f1)m(grep -n CALCULATION_METHOD {$i}*.csv | cut -d: -f1) -c w -c q {$i}*.csv
end

# F21, F22, F23 only: `VAL_TOTAL`, `VAL_RANGE_TOTAL`, and children after `LOT_COMBINING_CONTRACT_RIGHT`
for i in F21 F22 F23
    set l (grep -n OBJECT_CONTRACT/VAL_TOTAL, {$i}*.csv | cut -d: -f1)
    ex -c $l,$l+5m(grep -n LOT_COMBINING_CONTRACT_RIGHT {$i}*.csv | cut -d: -f1) -c w -c q {$i}*.csv
end

# F03, F06, F25 only: `NO_AWARDED_TO_GROUP` after `AWARDED_TO_GROUP`
for i in F03 F06 F25
    ex -c (grep -n /NO_AWARDED_TO_GROUP {$i}*.csv | cut -d: -f1)m(grep -n /AWARDED_TO_GROUP {$i}*.csv | cut -d: -f1) -c w -c q {$i}*.csv
end

# F03, F06, F21, F22 only: `D_ACCORDANCE_ARTICLE` and children after all
for i in F03 F06 F21 F22 F23 F25
    ex -c (grep -n D_ACCORDANCE_ARTICLE, {$i}*.csv | cut -d: -f1),(grep -n D_JUSTIFICATION {$i}*.csv | cut -d: -f1)m\$ -c w -c q {$i}*.csv
end
for i in F15
    for x in DIRECTIVE_2014_24_EU DIRECTIVE_2014_25_EU DIRECTIVE_2009_81_EC
        ex -c (grep -n $x/PT_NEGOTIATED_WITHOUT_PUBLICATION/D_ACCORDANCE_ARTICLE, {$i}*.csv | cut -d: -f1),(grep -n $x/PT_NEGOTIATED_WITHOUT_PUBLICATION/D_JUSTIFICATION {$i}*.csv | cut -d: -f1)m\$ -c w -c q $i*.csv
        ex -c (grep -n $x/PT_AWARD_CONTRACT_WITHOUT_CALL/, {$i}*.csv | head -n 1 | cut -d: -f1),(grep -n $x/PT_AWARD_CONTRACT_WITHOUT_CALL/D_JUSTIFICATION {$i}*.csv | cut -d: -f1)m\$ -c w -c q $i*.csv
    end
    for x in DIRECTIVE_2014_23_EU
        ex -c (grep -n $x/PT_AWARD_CONTRACT_WITHOUT_PUBLICATION/D_ACCORDANCE_ARTICLE, {$i}*.csv | cut -d: -f1),(grep -n $x/PT_AWARD_CONTRACT_WITHOUT_PUBLICATION/D_JUSTIFICATION {$i}*.csv | cut -d: -f1)m\$ -c w -c q $i*.csv
        ex -c (grep -n $x/PT_AWARD_CONTRACT_WITHOUT_CALL/, {$i}*.csv | head -n 1 | cut -d: -f1),(grep -n $x/PT_AWARD_CONTRACT_WITHOUT_CALL/D_JUSTIFICATION {$i}*.csv | cut -d: -f1)m\$ -c w -c q $i*.csv
    end
end

# `NUTS` after `TOWN`
for i in F01 F02 F03 F04 F05 F06 F07 F08 F12 F13 F14 F15 F20 F21 F22 F23 F24 F25 MOVE
    ex -c (grep -n ADDRESS_CONTRACTING_BODY/NUTS, {$i}*.csv | cut -d: -f1)m(grep -n ADDRESS_CONTRACTING_BODY/TOWN, {$i}*.csv | cut -d: -f1) -c w -c q {$i}*.csv
end
for i in F03 F06 F22 F23
    ex -c (grep -n ADDRESS_CONTRACTOR/NUTS, {$i}*.csv | cut -d: -f1)m(grep -n ADDRESS_CONTRACTOR/TOWN, {$i}*.csv | cut -d: -f1) -c w -c q {$i}*.csv
end
for i in F13
    ex -c (grep -n ADDRESS_WINNER/NUTS, {$i}*.csv | cut -d: -f1)m(grep -n ADDRESS_WINNER/TOWN, {$i}*.csv | cut -d: -f1) -c w -c q {$i}*.csv
end

# `NO_LOT_DIVISION` after `LOT_DIVISION`
for i in F01 F02 F03 F04 F05 F06 F15 F21 F23 F24 F25
    ex -c (grep -n /NO_LOT_DIVISION, {$i}*.csv | cut -d: -f1)m(grep -n /LOT_DIVISION, {$i}*.csv | cut -d: -f1) -c w -c q {$i}*.csv
end
