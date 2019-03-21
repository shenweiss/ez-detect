namespace HFO_ENGINE
{
    partial class SSH
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(SSH));
            this.SSH_title = new System.Windows.Forms.Label();
            this.UsernameLabel = new System.Windows.Forms.Label();
            this.SSH_save_btn = new System.Windows.Forms.Button();
            this.panel2 = new System.Windows.Forms.Panel();
            this.label3 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.Servername_comboBox = new System.Windows.Forms.ComboBox();
            this.label6 = new System.Windows.Forms.Label();
            this.label1 = new System.Windows.Forms.Label();
            this.Username_txt = new System.Windows.Forms.TextBox();
            this.panel1 = new System.Windows.Forms.Panel();
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.panel2.SuspendLayout();
            this.panel1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
            this.SuspendLayout();
            // 
            // SSH_title
            // 
            this.SSH_title.Font = new System.Drawing.Font("Arial", 18F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.SSH_title.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.SSH_title.Location = new System.Drawing.Point(-5, 0);
            this.SSH_title.Name = "SSH_title";
            this.SSH_title.Size = new System.Drawing.Size(177, 40);
            this.SSH_title.TabIndex = 3;
            this.SSH_title.Text = "SSH settings";
            // 
            // UsernameLabel
            // 
            this.UsernameLabel.BackColor = System.Drawing.Color.Transparent;
            this.UsernameLabel.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.UsernameLabel.Font = new System.Drawing.Font("Microsoft Sans Serif", 11F);
            this.UsernameLabel.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.UsernameLabel.Location = new System.Drawing.Point(3, 108);
            this.UsernameLabel.Name = "UsernameLabel";
            this.UsernameLabel.Size = new System.Drawing.Size(103, 22);
            this.UsernameLabel.TabIndex = 8;
            this.UsernameLabel.Text = "Username:";
            this.UsernameLabel.TextAlign = System.Drawing.ContentAlignment.BottomLeft;
            // 
            // SSH_save_btn
            // 
            this.SSH_save_btn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.SSH_save_btn.FlatAppearance.BorderSize = 2;
            this.SSH_save_btn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.SSH_save_btn.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold);
            this.SSH_save_btn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.SSH_save_btn.Location = new System.Drawing.Point(278, 286);
            this.SSH_save_btn.Name = "SSH_save_btn";
            this.SSH_save_btn.Size = new System.Drawing.Size(82, 34);
            this.SSH_save_btn.TabIndex = 17;
            this.SSH_save_btn.Text = "Save";
            this.SSH_save_btn.UseVisualStyleBackColor = true;
            this.SSH_save_btn.Click += new System.EventHandler(this.SSH_save_btn_Click);
            // 
            // panel2
            // 
            this.panel2.Controls.Add(this.label3);
            this.panel2.Controls.Add(this.label2);
            this.panel2.Controls.Add(this.Servername_comboBox);
            this.panel2.Controls.Add(this.label6);
            this.panel2.Controls.Add(this.SSH_save_btn);
            this.panel2.Controls.Add(this.UsernameLabel);
            this.panel2.Controls.Add(this.label1);
            this.panel2.Controls.Add(this.Username_txt);
            this.panel2.Location = new System.Drawing.Point(60, 166);
            this.panel2.Name = "panel2";
            this.panel2.Size = new System.Drawing.Size(360, 320);
            this.panel2.TabIndex = 18;
            // 
            // label3
            // 
            this.label3.BackColor = System.Drawing.Color.White;
            this.label3.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label3.Location = new System.Drawing.Point(3, 88);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(110, 2);
            this.label3.TabIndex = 32;
            // 
            // label2
            // 
            this.label2.BackColor = System.Drawing.Color.Transparent;
            this.label2.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 11F);
            this.label2.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label2.Location = new System.Drawing.Point(3, 65);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(103, 22);
            this.label2.TabIndex = 31;
            this.label2.Text = "Server name:";
            this.label2.TextAlign = System.Drawing.ContentAlignment.BottomLeft;
            // 
            // Servername_comboBox
            // 
            this.Servername_comboBox.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(90)))));
            this.Servername_comboBox.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Servername_comboBox.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.Servername_comboBox.FormattingEnabled = true;
            this.Servername_comboBox.Items.AddRange(new object[] {
            "Grito",
            "TJU"});
            this.Servername_comboBox.Location = new System.Drawing.Point(142, 66);
            this.Servername_comboBox.Name = "Servername_comboBox";
            this.Servername_comboBox.Size = new System.Drawing.Size(218, 21);
            this.Servername_comboBox.TabIndex = 30;
            // 
            // label6
            // 
            this.label6.BackColor = System.Drawing.Color.White;
            this.label6.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label6.Location = new System.Drawing.Point(3, 136);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(110, 2);
            this.label6.TabIndex = 29;
            // 
            // label1
            // 
            this.label1.BackColor = System.Drawing.Color.White;
            this.label1.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label1.Location = new System.Drawing.Point(122, 136);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(232, 2);
            this.label1.TabIndex = 21;
            // 
            // Username_txt
            // 
            this.Username_txt.Anchor = System.Windows.Forms.AnchorStyles.None;
            this.Username_txt.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.Username_txt.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.Username_txt.Font = new System.Drawing.Font("Microsoft Sans Serif", 11F);
            this.Username_txt.ForeColor = System.Drawing.SystemColors.Window;
            this.Username_txt.Location = new System.Drawing.Point(125, 111);
            this.Username_txt.Name = "Username_txt";
            this.Username_txt.ScrollBars = System.Windows.Forms.ScrollBars.Horizontal;
            this.Username_txt.Size = new System.Drawing.Size(232, 17);
            this.Username_txt.TabIndex = 20;
            // 
            // panel1
            // 
            this.panel1.Controls.Add(this.SSH_title);
            this.panel1.Controls.Add(this.pictureBox1);
            this.panel1.Location = new System.Drawing.Point(30, 50);
            this.panel1.Name = "panel1";
            this.panel1.Size = new System.Drawing.Size(390, 95);
            this.panel1.TabIndex = 19;
            // 
            // pictureBox1
            // 
            this.pictureBox1.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Zoom;
            this.pictureBox1.Image = ((System.Drawing.Image)(resources.GetObject("pictureBox1.Image")));
            this.pictureBox1.InitialImage = null;
            this.pictureBox1.Location = new System.Drawing.Point(295, 0);
            this.pictureBox1.Name = "pictureBox1";
            this.pictureBox1.Size = new System.Drawing.Size(95, 95);
            this.pictureBox1.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.pictureBox1.TabIndex = 9;
            this.pictureBox1.TabStop = false;
            // 
            // SSH
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.ClientSize = new System.Drawing.Size(480, 512);
            this.Controls.Add(this.panel2);
            this.Controls.Add(this.panel1);
            this.ForeColor = System.Drawing.SystemColors.Control;
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "SSH";
            this.Text = "SSH";
            this.panel2.ResumeLayout(false);
            this.panel2.PerformLayout();
            this.panel1.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Label SSH_title;
        private System.Windows.Forms.Label UsernameLabel;
        private System.Windows.Forms.Button SSH_save_btn;
        private System.Windows.Forms.Panel panel2;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.TextBox Username_txt;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.Panel panel1;
        private System.Windows.Forms.PictureBox pictureBox1;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.ComboBox Servername_comboBox;
        private System.Windows.Forms.Label label3;
    }
}