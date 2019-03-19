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
            Str_time_txt.Text = Program.StartTime.ToString();
            Stp_time_txt.Text = Program.StopTime.ToString();
        }

        private void TimeWindow_save_btn_Click(object sender, EventArgs e)
        {
            int str_time = int.Parse(Str_time_txt.Text, System.Globalization.CultureInfo.InvariantCulture);
            int stp_time = int.Parse(Stp_time_txt.Text, System.Globalization.CultureInfo.InvariantCulture);

            if (str_time < 1) {
                MessageBox.Show("Changes were NOT saved because Start time must be greater or equal to 1.");
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

    }
}
