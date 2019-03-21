namespace HFO_ENGINE
{
    partial class TimeWindow
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(TimeWindow));
            this.Times_title = new System.Windows.Forms.Label();
            this.StartTimeLabel = new System.Windows.Forms.Label();
            this.StopTimeLabel = new System.Windows.Forms.Label();
            this.TimeWindow_save_btn = new System.Windows.Forms.Button();
            this.panel2 = new System.Windows.Forms.Panel();
            this.label2 = new System.Windows.Forms.Label();
            this.skip1_label_snds = new System.Windows.Forms.Label();
            this.label1 = new System.Windows.Forms.Label();
            this.panel1 = new System.Windows.Forms.Panel();
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.label6 = new System.Windows.Forms.Label();
            this.skip1_label_mins = new System.Windows.Forms.Label();
            this.skip1_label_hs = new System.Windows.Forms.Label();
            this.label5 = new System.Windows.Forms.Label();
            this.label7 = new System.Windows.Forms.Label();
            this.size1_label_hs = new System.Windows.Forms.Label();
            this.size1_label_mins = new System.Windows.Forms.Label();
            this.label10 = new System.Windows.Forms.Label();
            this.size1_label_snds = new System.Windows.Forms.Label();
            this.skip_label_hs = new System.Windows.Forms.TextBox();
            this.skip_label_mins = new System.Windows.Forms.TextBox();
            this.skip_label_snds = new System.Windows.Forms.TextBox();
            this.size_label_hs = new System.Windows.Forms.TextBox();
            this.size_label_mins = new System.Windows.Forms.TextBox();
            this.size_label_snds = new System.Windows.Forms.TextBox();
            this.panel2.SuspendLayout();
            this.panel1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
            this.SuspendLayout();
            // 
            // Times_title
            // 
            this.Times_title.Font = new System.Drawing.Font("Arial", 18F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Times_title.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.Times_title.Location = new System.Drawing.Point(-5, 0);
            this.Times_title.Name = "Times_title";
            this.Times_title.Size = new System.Drawing.Size(189, 40);
            this.Times_title.TabIndex = 1;
            this.Times_title.Text = "Time window";
            // 
            // StartTimeLabel
            // 
            this.StartTimeLabel.BackColor = System.Drawing.Color.Transparent;
            this.StartTimeLabel.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.StartTimeLabel.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.StartTimeLabel.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.StartTimeLabel.Location = new System.Drawing.Point(37, 61);
            this.StartTimeLabel.Name = "StartTimeLabel";
            this.StartTimeLabel.Size = new System.Drawing.Size(173, 26);
            this.StartTimeLabel.TabIndex = 3;
            this.StartTimeLabel.Text = "Skip the first ...";
            // 
            // StopTimeLabel
            // 
            this.StopTimeLabel.BackColor = System.Drawing.Color.Transparent;
            this.StopTimeLabel.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.StopTimeLabel.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.StopTimeLabel.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.StopTimeLabel.Location = new System.Drawing.Point(37, 188);
            this.StopTimeLabel.Name = "StopTimeLabel";
            this.StopTimeLabel.Size = new System.Drawing.Size(173, 26);
            this.StopTimeLabel.TabIndex = 4;
            this.StopTimeLabel.Text = "Analize the following...";
            // 
            // TimeWindow_save_btn
            // 
            this.TimeWindow_save_btn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.TimeWindow_save_btn.FlatAppearance.BorderSize = 2;
            this.TimeWindow_save_btn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.TimeWindow_save_btn.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold);
            this.TimeWindow_save_btn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.TimeWindow_save_btn.Location = new System.Drawing.Point(278, 286);
            this.TimeWindow_save_btn.Name = "TimeWindow_save_btn";
            this.TimeWindow_save_btn.Size = new System.Drawing.Size(82, 34);
            this.TimeWindow_save_btn.TabIndex = 8;
            this.TimeWindow_save_btn.Text = "Save";
            this.TimeWindow_save_btn.UseVisualStyleBackColor = true;
            this.TimeWindow_save_btn.Click += new System.EventHandler(this.TimeWindow_save_btn_Click);
            // 
            // panel2
            // 
            this.panel2.Controls.Add(this.size_label_snds);
            this.panel2.Controls.Add(this.size_label_mins);
            this.panel2.Controls.Add(this.size_label_hs);
            this.panel2.Controls.Add(this.skip_label_snds);
            this.panel2.Controls.Add(this.skip_label_mins);
            this.panel2.Controls.Add(this.skip_label_hs);
            this.panel2.Controls.Add(this.label7);
            this.panel2.Controls.Add(this.size1_label_hs);
            this.panel2.Controls.Add(this.size1_label_mins);
            this.panel2.Controls.Add(this.label10);
            this.panel2.Controls.Add(this.size1_label_snds);
            this.panel2.Controls.Add(this.label5);
            this.panel2.Controls.Add(this.skip1_label_hs);
            this.panel2.Controls.Add(this.skip1_label_mins);
            this.panel2.Controls.Add(this.label6);
            this.panel2.Controls.Add(this.label2);
            this.panel2.Controls.Add(this.skip1_label_snds);
            this.panel2.Controls.Add(this.label1);
            this.panel2.Controls.Add(this.TimeWindow_save_btn);
            this.panel2.Controls.Add(this.StartTimeLabel);
            this.panel2.Controls.Add(this.StopTimeLabel);
            this.panel2.Location = new System.Drawing.Point(60, 166);
            this.panel2.Name = "panel2";
            this.panel2.Size = new System.Drawing.Size(388, 320);
            this.panel2.TabIndex = 11;
            // 
            // label2
            // 
            this.label2.BackColor = System.Drawing.Color.Transparent;
            this.label2.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label2.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label2.Location = new System.Drawing.Point(55, 120);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(62, 26);
            this.label2.TabIndex = 10;
            this.label2.Text = "And ";
            this.label2.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.label2.Click += new System.EventHandler(this.label2_Click);
            // 
            // skip1_label_snds
            // 
            this.skip1_label_snds.BackColor = System.Drawing.Color.Ivory;
            this.skip1_label_snds.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F);
            this.skip1_label_snds.ForeColor = System.Drawing.SystemColors.ActiveCaptionText;
            this.skip1_label_snds.Location = new System.Drawing.Point(312, 51);
            this.skip1_label_snds.Margin = new System.Windows.Forms.Padding(0);
            this.skip1_label_snds.Name = "skip1_label_snds";
            this.skip1_label_snds.Size = new System.Drawing.Size(28, 40);
            this.skip1_label_snds.TabIndex = 49;
            this.skip1_label_snds.Text = "00";
            this.skip1_label_snds.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label1
            // 
            this.label1.BackColor = System.Drawing.Color.Transparent;
            this.label1.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.label1.Location = new System.Drawing.Point(-4, 0);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(361, 26);
            this.label1.TabIndex = 9;
            this.label1.Text = "From the beginning of recording:";
            // 
            // panel1
            // 
            this.panel1.Controls.Add(this.Times_title);
            this.panel1.Controls.Add(this.pictureBox1);
            this.panel1.Location = new System.Drawing.Point(30, 50);
            this.panel1.Name = "panel1";
            this.panel1.Size = new System.Drawing.Size(390, 95);
            this.panel1.TabIndex = 13;
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
            // label6
            // 
            this.label6.BackColor = System.Drawing.Color.White;
            this.label6.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold);
            this.label6.ForeColor = System.Drawing.SystemColors.WindowText;
            this.label6.Location = new System.Drawing.Point(302, 51);
            this.label6.Margin = new System.Windows.Forms.Padding(0);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(10, 40);
            this.label6.TabIndex = 51;
            this.label6.Text = ":";
            this.label6.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // skip1_label_mins
            // 
            this.skip1_label_mins.BackColor = System.Drawing.Color.Ivory;
            this.skip1_label_mins.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F);
            this.skip1_label_mins.ForeColor = System.Drawing.SystemColors.ActiveCaptionText;
            this.skip1_label_mins.Location = new System.Drawing.Point(274, 51);
            this.skip1_label_mins.Margin = new System.Windows.Forms.Padding(0);
            this.skip1_label_mins.Name = "skip1_label_mins";
            this.skip1_label_mins.Size = new System.Drawing.Size(28, 40);
            this.skip1_label_mins.TabIndex = 53;
            this.skip1_label_mins.Text = "00";
            this.skip1_label_mins.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // skip1_label_hs
            // 
            this.skip1_label_hs.BackColor = System.Drawing.Color.Ivory;
            this.skip1_label_hs.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F);
            this.skip1_label_hs.ForeColor = System.Drawing.SystemColors.ActiveCaptionText;
            this.skip1_label_hs.Location = new System.Drawing.Point(236, 51);
            this.skip1_label_hs.Margin = new System.Windows.Forms.Padding(0);
            this.skip1_label_hs.Name = "skip1_label_hs";
            this.skip1_label_hs.Size = new System.Drawing.Size(28, 40);
            this.skip1_label_hs.TabIndex = 54;
            this.skip1_label_hs.Text = "00";
            this.skip1_label_hs.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label5
            // 
            this.label5.BackColor = System.Drawing.Color.White;
            this.label5.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold);
            this.label5.ForeColor = System.Drawing.SystemColors.WindowText;
            this.label5.Location = new System.Drawing.Point(264, 51);
            this.label5.Margin = new System.Windows.Forms.Padding(0);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(10, 40);
            this.label5.TabIndex = 55;
            this.label5.Text = ":";
            this.label5.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label7
            // 
            this.label7.BackColor = System.Drawing.Color.White;
            this.label7.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold);
            this.label7.ForeColor = System.Drawing.SystemColors.WindowText;
            this.label7.Location = new System.Drawing.Point(264, 178);
            this.label7.Margin = new System.Windows.Forms.Padding(0);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(10, 40);
            this.label7.TabIndex = 60;
            this.label7.Text = ":";
            this.label7.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // size1_label_hs
            // 
            this.size1_label_hs.BackColor = System.Drawing.Color.Ivory;
            this.size1_label_hs.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F);
            this.size1_label_hs.ForeColor = System.Drawing.SystemColors.ActiveCaptionText;
            this.size1_label_hs.Location = new System.Drawing.Point(236, 178);
            this.size1_label_hs.Margin = new System.Windows.Forms.Padding(0);
            this.size1_label_hs.Name = "size1_label_hs";
            this.size1_label_hs.Size = new System.Drawing.Size(28, 40);
            this.size1_label_hs.TabIndex = 59;
            this.size1_label_hs.Text = "00";
            this.size1_label_hs.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // size1_label_mins
            // 
            this.size1_label_mins.BackColor = System.Drawing.Color.Ivory;
            this.size1_label_mins.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F);
            this.size1_label_mins.ForeColor = System.Drawing.SystemColors.ActiveCaptionText;
            this.size1_label_mins.Location = new System.Drawing.Point(274, 178);
            this.size1_label_mins.Margin = new System.Windows.Forms.Padding(0);
            this.size1_label_mins.Name = "size1_label_mins";
            this.size1_label_mins.Size = new System.Drawing.Size(28, 40);
            this.size1_label_mins.TabIndex = 58;
            this.size1_label_mins.Text = "00";
            this.size1_label_mins.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // label10
            // 
            this.label10.BackColor = System.Drawing.Color.White;
            this.label10.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold);
            this.label10.ForeColor = System.Drawing.SystemColors.WindowText;
            this.label10.Location = new System.Drawing.Point(302, 178);
            this.label10.Margin = new System.Windows.Forms.Padding(0);
            this.label10.Name = "label10";
            this.label10.Size = new System.Drawing.Size(10, 40);
            this.label10.TabIndex = 57;
            this.label10.Text = ":";
            this.label10.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // size1_label_snds
            // 
            this.size1_label_snds.BackColor = System.Drawing.Color.Ivory;
            this.size1_label_snds.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F);
            this.size1_label_snds.ForeColor = System.Drawing.SystemColors.ActiveCaptionText;
            this.size1_label_snds.Location = new System.Drawing.Point(312, 178);
            this.size1_label_snds.Margin = new System.Windows.Forms.Padding(0);
            this.size1_label_snds.Name = "size1_label_snds";
            this.size1_label_snds.Size = new System.Drawing.Size(28, 40);
            this.size1_label_snds.TabIndex = 56;
            this.size1_label_snds.Text = "00";
            this.size1_label_snds.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // skip_label_hs
            // 
            this.skip_label_hs.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.skip_label_hs.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.skip_label_hs.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F);
            this.skip_label_hs.Location = new System.Drawing.Point(240, 61);
            this.skip_label_hs.Name = "skip_label_hs";
            this.skip_label_hs.Size = new System.Drawing.Size(24, 19);
            this.skip_label_hs.TabIndex = 61;
            this.skip_label_hs.Text = "00";
            // 
            // skip_label_mins
            // 
            this.skip_label_mins.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.skip_label_mins.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.skip_label_mins.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F);
            this.skip_label_mins.Location = new System.Drawing.Point(277, 61);
            this.skip_label_mins.Name = "skip_label_mins";
            this.skip_label_mins.Size = new System.Drawing.Size(24, 19);
            this.skip_label_mins.TabIndex = 62;
            this.skip_label_mins.Text = "00";
            // 
            // skip_label_snds
            // 
            this.skip_label_snds.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.skip_label_snds.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.skip_label_snds.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F);
            this.skip_label_snds.Location = new System.Drawing.Point(316, 61);
            this.skip_label_snds.Name = "skip_label_snds";
            this.skip_label_snds.Size = new System.Drawing.Size(24, 19);
            this.skip_label_snds.TabIndex = 63;
            this.skip_label_snds.Text = "00";
            // 
            // size_label_hs
            // 
            this.size_label_hs.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.size_label_hs.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.size_label_hs.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F);
            this.size_label_hs.Location = new System.Drawing.Point(240, 188);
            this.size_label_hs.Name = "size_label_hs";
            this.size_label_hs.Size = new System.Drawing.Size(24, 19);
            this.size_label_hs.TabIndex = 64;
            this.size_label_hs.Text = "00";
            // 
            // size_label_mins
            // 
            this.size_label_mins.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.size_label_mins.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.size_label_mins.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F);
            this.size_label_mins.Location = new System.Drawing.Point(277, 188);
            this.size_label_mins.Name = "size_label_mins";
            this.size_label_mins.Size = new System.Drawing.Size(24, 19);
            this.size_label_mins.TabIndex = 65;
            this.size_label_mins.Text = "00";
            // 
            // size_label_snds
            // 
            this.size_label_snds.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.size_label_snds.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.size_label_snds.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F);
            this.size_label_snds.Location = new System.Drawing.Point(316, 188);
            this.size_label_snds.Name = "size_label_snds";
            this.size_label_snds.Size = new System.Drawing.Size(24, 19);
            this.size_label_snds.TabIndex = 66;
            this.size_label_snds.Text = "00";
            // 
            // TimeWindow
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.ClientSize = new System.Drawing.Size(480, 512);
            this.Controls.Add(this.panel2);
            this.Controls.Add(this.panel1);
            this.ForeColor = System.Drawing.Color.Black;
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "TimeWindow";
            this.Text = "TimeWindow";
            this.panel2.ResumeLayout(false);
            this.panel2.PerformLayout();
            this.panel1.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Label Times_title;
        private System.Windows.Forms.Label StartTimeLabel;
        private System.Windows.Forms.Label StopTimeLabel;
        private System.Windows.Forms.Button TimeWindow_save_btn;
        private System.Windows.Forms.Panel panel2;
        private System.Windows.Forms.Panel panel1;
        private System.Windows.Forms.PictureBox pictureBox1;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label skip1_label_snds;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.Label size1_label_hs;
        private System.Windows.Forms.Label size1_label_mins;
        private System.Windows.Forms.Label label10;
        private System.Windows.Forms.Label size1_label_snds;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.Label skip1_label_hs;
        private System.Windows.Forms.Label skip1_label_mins;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.TextBox skip_label_hs;
        private System.Windows.Forms.TextBox skip_label_mins;
        private System.Windows.Forms.TextBox skip_label_snds;
        private System.Windows.Forms.TextBox size_label_hs;
        private System.Windows.Forms.TextBox size_label_mins;
        private System.Windows.Forms.TextBox size_label_snds;
    }
}