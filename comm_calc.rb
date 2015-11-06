#!/usr/bin/env ruby

# version 0.1.1

require 'green_shoes'
require 'ordinalize_full/integer'

class Calc
  def base(amount)
    amount = amount.to_f
    # is this next part un-ruby-ish? I'm not sure...I'm condensing.
    return (0).to_f if self.under?(amount)
    return (amount.to_f * 0.15) if self.percent_15?(amount)
    return ((amount.to_f - 6000) * 0.40) + (6000 * 0.2) if self.percent_20_40?(amount)
  end

  def under?(amt)
    (0...4200) === amt
  end

  def percent_15?(amt)
  (4200...6000) === amt
  end

  def percent_20_40?(amt)
    6000.0 <= amt
  end
end

class Verify
  def initialize
    $deal_iterator ||= 0
  end

  def deal(dealnum)
    dealnum = dealnum.delete(" ").upcase
    $deal_iterator += 1
    if dealnum == ""
      # if the deal number is blank, give it a generic name like "1st Store", "2nd Store", etc
      return "#{$deal_iterator.ordinalize} Store"
    else
      # otherwise keep deal number the same
      return dealnum
    end
  end

  # Negative numbers are never needed when calculating commissions.
  # This method will convert any negative number to a positive
  def not_negative(num)
    if num < 0
      return (num * -1.0)
    else
      return num
    end
  end
end

Shoes.app :title => "", :width => 800, :height => 460, :resizable => false do

  stack :width => '100%', :height => '100%' do
    flow :width => '100%', :height => 45 do
      border gray, strokewidth: 0.5
      para code("Commission Calculator"), :stroke => red, :align => 'center', :margin => 13, :weight => 'bold', :size => 'large'
    end

    flow :width => '100%', :height => '100%' do
      stack :width => '85%', :height => '100%' do
        flow :width => '100%', :height => 60  do
          # input fields go here
          #border gray, strokewidth: 1
          stack :width => 113, :height => 60 do
            border gray, strokewidth: 0.5
            flow :width => 113, :height => 27 do
              para "Deal#", :align => 'center', :margin_top => 5
            end
            flow :width => 113, :height => 33 do
              @deal = edit_line :margin_left => 19
              @deal.style(:width => 75)
            end
          end

          stack :width => 113, :height => 60 do
            border gray, strokewidth: 0.5
            flow :width => 113, :height => 27 do
              para "Amt on Store", :align => 'center', :margin_top => 5
            end
            flow :width => 113, :height => 33 do
              @already_on_store = edit_line :margin_left => 19
              @already_on_store.style(:width => 75)
            end
          end

          stack :width => 113, :height => 60 do
            border gray, strokewidth: 0.5
            flow :width => 113, :height => 27 do
              para "6 Mo Totals", :align => 'center', :margin_top => 5
            end
            flow :width => 113, :height => 33 do
              @six_totals = edit_line :margin_left => 19
              @six_totals.style(:width => 75)
            end
          end

          stack :width => 113, :height => 60 do
            border gray, strokewidth: 0.5
            flow :width => 113, :height => 27 do
              para "12 Mo Totals", :align => 'center', :margin_top => 5
            end
            flow :width => 113, :height => 33 do
              @twelve_totals = edit_line :margin_left => 19
              @twelve_totals.style(:width => 75)
            end
          end

          stack :width => 113, :height => 60 do
            border gray, strokewidth: 0.5
            flow :width => 113, :height => 27 do
              para "Opt 1-4", :align => 'center', :margin_top => 5
            end
            flow :width => 113, :height => 33 do
              @opt14 = edit_line :margin_left => 19
              @opt14.style(:width => 75)
            end
          end

          stack :width => 113, :height => 60 do
            border gray, strokewidth: 0.5
            flow :width => 113, :height => 27 do
              para "A/S Comm", :align => 'center', :margin_top => 5
            end
            flow :width => 113, :height => 33 do
              @a_s_comm = edit_line :margin_left => 19
              @a_s_comm.style(:width => 75)
            end
          end
        end

        flow :width => '100%', :height => 345 do
          #text output goes here
          @show = edit_box("", width: '99.8%', height: '100%')
        end
      end

      stack :width => '15%', :height => '100%' do
        flow :width => '100%', :height => 35, :margin => 10 do
          @calc = button("Calculate") {
            verify = Verify.new
            @prev_str ||= ""

            # Here are the various values defined by the user.
            deal_num =  verify.deal(@deal.text)
            six_mo = verify.not_negative(@six_totals.text.to_f)
            twelve_mo = verify.not_negative(@twelve_totals.text.to_f)
            opt14 = verify.not_negative(@opt14.text.to_f)
            sales_prev = verify.not_negative(@already_on_store.text.to_f)
            as_comm = verify.not_negative(@a_s_comm.text.to_f)

            # Calculating some values...
            comm_prev = Calc.new.base(sales_prev)
            sales_new = six_mo + (twelve_mo /2)
            comm_new = Calc.new.base(sales_new + sales_prev) - comm_prev
            bonus_opt14 = opt14 * 0.02
            bonus_annual = twelve_mo * 0.01
            penalty_6mo = six_mo * -0.01
            total_comm = comm_new + bonus_opt14 + bonus_annual + penalty_6mo - as_comm

            # Lambda that formats a float to two decimal places ($ USD)
            money = lambda {|num| format('%.2f', num)}

            # Building string for output...
            my_str = %Q(
            -----------------------------------------------------
            | Deal Number: #{deal_num}
            -----------------------------------------------------
            | Already Sold on Store:........$#{money.call(sales_prev)}
            | Already Paid to Rep:..........$#{money.call(comm_prev)}
            -----------------------------------------------------
            | Recently Sold:................$#{money.call(sales_new)}
            | Rep Commission:...............$#{money.call(comm_new)}
            | Rep Bonus (Opt 1-4):..........$#{money.call(bonus_opt14)}
            | Rep Bonus (Annual):...........$#{money.call(bonus_annual)}
            | Rep Penalty (6-Month):........$#{money.call(penalty_6mo)}
            | Appt. Setter Commissions:.....$-#{money.call(as_comm)}
            -----------------------------------------------------
            | Total Due to Rep:.............$#{money.call(total_comm)}
            -----------------------------------------------------
            )

            # Outputting to edit_box...
            @show.text = my_str + @prev_str

            @prev_str = my_str + @prev_str
          }
          @calc.style(:width => 100, :height => 35)
        end
        #keypress { |k| @calc.start if k == '\n' }
        flow :width => 100, :height => 255, :margin_top => 20, :margin => 10 do
          @clear = button("Clear") {
            @show.text = ""
            @deal.text = ""
            @already_on_store.text = ""
            @six_totals.text = ""
            @twelve_totals.text = ""
            @opt14.text = ""
            @a_s_comm.text = ""
            @prev_str = ""
            $deal_iterator = 0 #I'm not sure if the user would want to reset the deal iterator
          }
          @clear.style(:width => 100, :height => 35)

        end
        flow :width => 100, :height => 50, :margin_left => 35  do
          @help = para link( 'Help') {
            Shoes.app :title => "Help", :width => 600, :height => 600, :resizable => false, :margin_top => 20 do
              background white
              stack :align => 'center', :margin => 10 do
                para code('Help Documentation'), :stroke => red, :align => 'center', :weight => 'bold', :size => 'xx-large'
                inscription "***Attention: do not include Production Charges in any of your numbers!", :align => 'center'
                para strong('Glossary of Terms'), :size => 'large', :underline => 'single'
                para strong('Deal#'), ' is optional. This is mean to help you keep track of which stores the calculation belong to. (e.g. CAL 1541)'
                para strong('Amt on Store'), ' enter the current total dollar amount you have on this store. Which means you\'re only entering the amount that goes towards your commission. For example, if you sold a $6000 annual last week, and nothing was sold prior to that, the "Amt on Store" is only $3000.'
                para strong('6 Month Totals'), ' enter the sum of all 6-Month contracts. Do not include Production Charges.'
                para strong('12 Month Totals'), ' enter the sum of all 12-Month contracts. Do not include Production Charges.'
                para strong('Option 1-4'), ' enter the sum of all contracts that have Option 1-4. Do not include Production Charges.'
                para strong('A/S Commission'), ' enter the sum of all appointment setter fees to be taken out of your check.'
                inscription "*If you uncover a bug in the program or you are still having trouble, please contact the developer at brianjason@gmail.com", :emphasis => 'italic'

              end
            end
          }

          @about = para link('About') {
            Shoes.app :title => "About", :width => 325, :height => 325, :resizable => false, :margin_top => 20 do
              background whitesmoke

              stack :align => 'center', :margin_top => 10 do
                para code('Commission Calculator'), :stroke => red, :align => 'center', :weight => 'bold', :size => 'large'
                inscription 'Version 0.1.0', :align => 'center'
                para ""
                para strong('Created by:'), ' Brian Jason', :align => 'center'
                inscription strong('Email:'), ' brianjason@gmail.com', :align => 'center'
                para ""

                inscription "Copyright 2015. Licensed under a Creative Commons Attribution-NoDerivatives 4.0 International License.", :align => 'center', :size => 'small'
                inscription " ", :size => 'xx-small'
                @ccimg = image 'https://i.creativecommons.org/l/by-nd/4.0/88x31.png', :margin_left => 115
            end
          end
           }

        end

        flow :width => 100, :height => 45, :margin => 10 do
          @exit = button("Exit") {exit()}
          @exit.style(:width => 100, :height => 35)
        end
      end
    end
  end
end
