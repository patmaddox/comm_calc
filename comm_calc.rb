#!/usr/bin/env ruby
# <alpha release>
# version 0.1.0 

require 'green_shoes'
require 'ordinalize_full/integer'
require 'money'

class Calculate
  def initialize(app)
    @app = app
    $deal_iterator = 0
  end

  def commission(deal, already, six_mo, twelve_mo, opts, as_comm)
    @entered_values = {:amount_on_store => already.to_f, :six_month_totals => six_mo.to_f, :twelve_month_totals => twelve_mo.to_f, :option_14 => opts.to_f, :appt_setter_commission => as_comm.to_f}
    @deal_num = {:deal_num => deal.delete(" ").upcase}
    #@deal_num[:deal_num] = @deal_num[:deal_num].delete(",") # good!
    @deal_num[:deal_num] = self.verify_dealnum # good!

    if !self.verify_values
      # an alert pops up
      @app.alert("#{value} is a negative number...\n(#{key} = #{value})\n\nAre you sure that's the right value?")
    end

    @entered_values.merge!(@deal_num) #good! #this hash will be returned to Shoes

    # Evaluating Commission, hence "comm_eval"
    @comm_eval = Hash.new # good!
    @comm_eval[:already_paid] = self.already_paid(@entered_values[:amount_on_store]) # good!
    @comm_eval[:rep_owed_on_totals] = self.rep_owed_on_totals
    @comm_eval[:rep_bonus_option_14] = self.rep_bonus_opt14
    @comm_eval[:rep_bonus_annual] = self.rep_bonus_annuals
    @comm_eval[:rep_penalty_6_mo] = self.rep_penalty_6mo
    @comm_eval[:rep_total_owed_now] = self.add_it_up - @entered_values[:appt_setter_commission]
    @comm_eval[:new_amount_on_store] = @new_amount_on_store
    return @comm_eval.merge!(@entered_values)

  end

  def verify_dealnum
    # if the deal number is blank, give it a generic name like "1st Store", "2nd Store", etc
    # otherwise keep deal number the same
    $deal_iterator += 1
    if @deal_num[:deal_num] == ""
      return "#{$deal_iterator.ordinalize} Store"
    else
      return @deal_num[:deal_num]
    end
  end

  def verify_values
    @entered_values.each do |key, value|
      if value < 0
        return false
      end
    end
  end

  def already_paid(already)
    if already < 4200
      paid = (0).to_f
    elsif already >= 4200 && already < 6000
      paid = (already.to_f * 0.15)
    elsif already >= 6000
      paid = ((already.to_f - 6000) * 0.40) + (6000 * 0.2)
    end
    return paid
  end

  def rep_owed_on_totals
    # commission owed on new 6 and 12 month contracts
    @new_amount_on_store = @entered_values[:amount_on_store] + @entered_values[:six_month_totals] + (@entered_values[:twelve_month_totals] /2)
    @new_commission_on_store = self.already_paid(@new_amount_on_store)
    return @new_commission_on_store - @comm_eval[:already_paid]
  end

  def rep_bonus_opt14
    # 2% bonus
    return @entered_values[:option_14] * 0.02
  end

  def rep_bonus_annuals
    # +1% bonus
    return @entered_values[:twelve_month_totals] * 0.01
  end

  def rep_penalty_6mo
    # -1% penalty
    return @entered_values[:six_month_totals] * -0.01
  end

  def add_it_up
    return @comm_eval[:rep_owed_on_totals] + @comm_eval[:rep_bonus_option_14] + @comm_eval[:rep_bonus_annual] + @comm_eval[:rep_penalty_6_mo]
  end
end


Shoes.app :title => "", :width => 800, :height => 460, :resizable => false do
  #initialize Calculate class instance
  @calculate = Calculate.new(self)
  @prev_str = ""

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
            calculated = @calculate.commission(@deal.text, @already_on_store.text, @six_totals.text, @twelve_totals.text, @opt14.text, @a_s_comm.text)

            my_str = %Q(
            -----------------------------------------------------
            | Deal Number: #{calculated[:deal_num]}
            -----------------------------------------------------
            | Already Sold on Store:........#{Money.new(calculated[:amount_on_store]*100, "USD").format}
            | Already Paid to Rep:............#{Money.new(calculated[:already_paid]*100, "USD").format}
            -----------------------------------------------------
            | Recently Sold:............................#{Money.new((calculated[:six_month_totals]+calculated[:twelve_month_totals])*100, "USD").format}
            | Rep Commission:......................#{Money.new(calculated[:rep_owed_on_totals]*100, "USD").format}
            | Rep Bonus (Opt 1-4):................#{Money.new(calculated[:rep_bonus_option_14]*100, "USD").format}
            | Rep Bonus (Annual):.................#{Money.new(calculated[:rep_bonus_annual]*100, "USD").format}
            | Rep Penalty (6-Month):............#{Money.new(calculated[:rep_penalty_6_mo]*100, "USD").format}
            | Appt. Setter Commissions:.....#{Money.new(calculated[:appt_setter_commission]*100, "USD").format}
            -----------------------------------------------------
            | Total Due to Rep:...........#{Money.new(calculated[:rep_total_owed_now]*100, "USD").format}
            -----------------------------------------------------\n\n
            )

            @show.text = my_str + @prev_str
            @prev_str = my_str + @prev_str

          }
          @calc.style(:width => 100, :height => 35)
        end

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
