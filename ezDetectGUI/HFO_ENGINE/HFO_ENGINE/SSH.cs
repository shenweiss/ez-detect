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
    public partial class SSH : Form
    {
        public SSH()
        {
            InitializeComponent();
            Hostname_txt.Text = Program.Hostname;
            Username_txt.Text = Program.Username;
            Session_txt.Text = Program.Host_conf;
            Remote_trc_txt.Text = Program.Remote_trc_dir;
            Remote_evt_txt.Text = Program.Remote_evt_dir;
        }

        private void SSH_save_btn_Click(object sender, EventArgs e)
        {
            Program.Hostname = Hostname_txt.Text;
            Program.Username = Username_txt.Text;
            Program.Host_conf = Session_txt.Text;
            Program.Remote_trc_dir = Remote_trc_txt.Text;
            Program.Remote_evt_dir = Remote_evt_txt.Text;
        }

    }
}
