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
    public partial class CycleTime : Form
    {
        public CycleTime()
        {
            InitializeComponent();
            Parallel_chk_bx.Checked = Program.MultiProcessingEnabled;
            if (Parallel_chk_bx.Checked)
            {
                if (Convert.ToInt32(c_time_1_rBtn.Text) == Program.CycleTimeMin) c_time_1_rBtn.Checked = true;
                if (Convert.ToInt32(c_time_2_rBtn.Text) == Program.CycleTimeMin) c_time_2_rBtn.Checked = true;
                if (Convert.ToInt32(c_time_3_rBtn.Text) == Program.CycleTimeMin) c_time_3_rBtn.Checked = true;
                if (Convert.ToInt32(c_time_4_rBtn.Text) == Program.CycleTimeMin) c_time_4_rBtn.Checked = true;

            }
            else {

                c_time_1_rBtn.Enabled = false;
                c_time_2_rBtn.Enabled = false;
                c_time_3_rBtn.Enabled = false;
                c_time_4_rBtn.Enabled = false;
            }
        }
        private void Parallel_chk_bx_CheckedChanged(object sender, EventArgs e)
        {
            CheckBox box = sender as CheckBox;
            if (box.Checked) Check(sender, e);
            else Uncheck(sender, e);

        }
        private void Check(object sender, EventArgs e)
        {
            this.c_time_1_rBtn.Enabled = true;
            this.c_time_2_rBtn.Enabled = true;
            this.c_time_3_rBtn.Enabled = true;
            this.c_time_4_rBtn.Enabled = true;
        }
        private void Uncheck(object sender, EventArgs e)
        {
            this.c_time_1_rBtn.Checked = false;
            this.c_time_2_rBtn.Checked = false;
            this.c_time_3_rBtn.Checked = false;
            this.c_time_4_rBtn.Checked = false;
          
            this.c_time_1_rBtn.Enabled = false;
            this.c_time_2_rBtn.Enabled = false;
            this.c_time_3_rBtn.Enabled = false;
            this.c_time_4_rBtn.Enabled = false;
        }

        private void CycleTime_save_btn_Click(object sender, EventArgs e)
        {

            Program.MultiProcessingEnabled = Parallel_chk_bx.Checked;
            if (Parallel_chk_bx.Checked)
            {

                if (c_time_1_rBtn.Checked)
                {
                    int value = Convert.ToInt32(c_time_1_rBtn.Text);
                    Program.CycleTime = value * 60;
                    Program.CycleTimeMin = value;
                }
                if (c_time_2_rBtn.Checked)
                {
                    int value = Convert.ToInt32(c_time_2_rBtn.Text);
                    Program.CycleTime = value * 60;
                    Program.CycleTimeMin = value;
                }
                if (c_time_3_rBtn.Checked)
                {
                    int value = Convert.ToInt32(c_time_3_rBtn.Text);
                    Program.CycleTime = value * 60;
                    Program.CycleTimeMin = value;
                }
                if (c_time_4_rBtn.Checked)
                {
                    int value = Convert.ToInt32(c_time_4_rBtn.Text);
                    Program.CycleTime = value * 60;
                    Program.CycleTimeMin = value;
                }
            }
            else { 
                Program.CycleTime = -1;
                Program.CycleTimeMin = 0;
            }

        }
    }


}
