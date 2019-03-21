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
    public partial class Progress : Form
    {
        public Progress()
        {
            InitializeComponent();
            int hs = snds / 3600;
            previous_hs_txt.Text = hs.ToString("D2");
            int min = (snds - hs * 3600) / 60;
            previous_min_txt.Text = min.ToString("D2");
            previous_snds_txt.Text = (snds - hs * 3600 - min * 60).ToString("D2");

            //Reset counters
            snds = 0;
            hours_label.Text = "00";
            minutes_label.Text = "00";
            seconds_label.Text = "00";

            ProgressBar.DataBindings.Add("Value", Program.mainForm,"WorkerState");
            timer.Start();

        }

        private int snds = 0;
        public void Stop_timer()
        {
            this.timer.Stop();
        }
        private void timer_Tick(object sender, EventArgs e)
        {
            snds++;
            int hs = snds / 3600;
            hours_label.Text = hs.ToString("D2");
            int min = (snds - hs * 3600) / 60;
            minutes_label.Text = min.ToString("D2");
            seconds_label.Text = (snds - hs * 3600 - min * 60).ToString("D2"); 

        }

    }
}
