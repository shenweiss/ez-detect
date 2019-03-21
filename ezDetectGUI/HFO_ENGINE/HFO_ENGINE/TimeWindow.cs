using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace HFO_ENGINE
{
    public partial class TimeWindow : Form
    {
        public TimeWindow()
        {
            InitializeComponent();

            seconds_to_timer(Program.StartTime - 1, skip_time);
            seconds_to_timer(Program.StopTime - Program.StartTime + 1, w_size_time);
        }

        private void seconds_to_timer(int seconds, DateTimePicker dt) {
            int hs = seconds / 3600;
            int mins = (seconds - hs * 3600) / 60;
            int snds = seconds - hs * 3600 - mins * 60;
            dt.Value = new DateTime(2020, 1, 1, hs, mins, snds);
        }

        private int timer_to_seconds(DateTimePicker dt)
        {
            return ( dt.Value.Second + dt.Value.Minute * 60 + dt.Value.Hour *3600);
        }

        private void TimeWindow_save_btn_Click(object sender, EventArgs e)
        {
            int str_time = timer_to_seconds(skip_time) + 1; 
            int stp_time = str_time + timer_to_seconds(w_size_time) - 1;

            if (str_time < 1) {
                MessageBox.Show("Start time must be greater than 0.");
                return;
            }
            if (stp_time > Program.Trc_duration) {
                MessageBox.Show("Changes were NOT saved because Stop time is greater than TRC_duration (" + Program.Trc_duration.ToString() + " seconds ).");
                return;
            }

            Program.StartTime = str_time;
            Program.StopTime = stp_time;


        }


    }
}
