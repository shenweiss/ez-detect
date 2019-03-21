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

            seconds_to_timer(Program.StartTime - 1, skip1_label_hs, skip1_label_mins, skip1_label_snds);
            seconds_to_timer(Program.StopTime, size1_label_hs, size1_label_mins, size1_label_snds);
        }

        private void seconds_to_timer(int seconds, Label label_hs, Label label_mins, Label label_snds) {
            int hs = seconds / 3600;
            label_hs.Text = hs.ToString("D2");
            int mins = (seconds - hs * 3600) / 60;
            label_mins.Text = mins.ToString("D2");
            label_snds.Text = (seconds - hs *3600 - mins * 60).ToString("D2");
        }

        //BUG VER  https://www.youtube.com/watch?v=Fb1XZEijPlw
        private int timer_to_seconds(Label label_hs, Label label_mins, Label label_snds)
        {
            return ( Convert.ToInt32(label_snds.Text) + Convert.ToInt32(label_mins.Text) * 60 + Convert.ToInt32(label_hs.Text) *3600);
        }

        private void TimeWindow_save_btn_Click(object sender, EventArgs e)
        {
            int str_time = timer_to_seconds(skip1_label_hs, skip1_label_mins, skip1_label_snds) + 1; 
            int stp_time = str_time + timer_to_seconds(size1_label_hs, size1_label_mins, size1_label_snds) - 1;

            if (str_time < 1) {
                MessageBox.Show("Changes were NOT saved because Skip time must be greater or equal to 0 seconds.");
                return;
            }
            if (stp_time > Program.Trc_duration) {
                MessageBox.Show("Changes were NOT saved because Stop time is greater than TRC_duration (" + Program.Trc_duration.ToString() + ").");
                return;
            }
            if (str_time > stp_time)
            {
                MessageBox.Show("Changes were NOT saved because Stop time must be greater than Start time.");
                return;
            }

            Program.StartTime = str_time;
            Program.StopTime = stp_time;

        }

        private void minutes_label_Click(object sender, EventArgs e)
        {

        }

        private void label2_Click(object sender, EventArgs e)
        {

        }
    }
}
