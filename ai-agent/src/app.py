"""
Streamlit Web UI for EC2 Terraform Agent
Run with: streamlit run app.py
"""

import streamlit as st
import json
from langchain_community.llms import Ollama
from langchain.prompts import PromptTemplate
from langchain.chains import LLMChain

st.set_page_config(
    page_title="EC2 Terraform Agent",
    page_icon="🤖",
    layout="wide"
)

st.title("🤖 EC2 Terraform Agent")
st.markdown("*Generate Terraform configurations using AI*")

with st.sidebar:
    st.header("⚙️ Configuration")
    ollama_host = st.text_input(
        "Ollama API URL",
        value="http://localhost:11434",
        help="URL where Ollama is running"
    )
    
    st.markdown("---")
    st.markdown("### 📚 Examples")
    st.code("3 t3.medium instances in us-west-2")
    st.code("5 small instances for my web app")
    st.code("2 t3.large instances with Ollama")

col1, col2 = st.columns([1, 1])

with col1:
    st.header("📝 Your Requirements")
    
    user_input = st.text_area(
        "Describe what you need:",
        placeholder="I need 3 t3.medium EC2 instances in us-west-2 for my application",
        height=100
    )
    
    st.markdown("**OR use the form below:**")
    
    with st.form("ec2_form"):
        instance_count = st.number_input("Number of instances", min_value=1, max_value=10, value=2)
        instance_type = st.selectbox(
            "Instance type",
            ["t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge"]
        )
        region = st.selectbox(
            "AWS Region",
            ["us-east-1", "us-west-2", "eu-west-1", "eu-central-1", "ap-southeast-1"]
        )
        project_name = st.text_input("Project name", value="my-ec2-project")
        
        use_form = st.form_submit_button("Generate from Form")
    
    generate_btn = st.button("🚀 Generate Terraform Config", type="primary", disabled=not user_input)

with col2:
    st.header("📊 Generated Configuration")
    
    if generate_btn or use_form:
        with st.spinner("🤖 AI is generating your Terraform configuration..."):
            try:
                llm = Ollama(
                    model="llama3",
                    base_url=ollama_host,
                    temperature=0.1
                )
                
                if use_form:
                    requirements = {
                        "instance_count": instance_count,
                        "instance_type": instance_type,
                        "region": region,
                        "project_name": project_name
                    }
                else:
                    parse_prompt = f"""Extract information from this request:
Request: "{user_input}"

Return ONLY valid JSON with: instance_count, instance_type, region, project_name
Example: {{"instance_count": 2, "instance_type": "t3.small", "region": "us-east-1", "project_name": "my-project"}}
"""
                    
                    response = llm.invoke(parse_prompt)
                    start = response.find('{')
                    end = response.rfind('}') + 1
                    json_str = response[start:end]
                    requirements = json.loads(json_str)
                
                st.success("✅ Requirements understood!")
                
                st.markdown("### 📋 Parsed Requirements")
                cols = st.columns(4)
                cols[0].metric("Instances", requirements['instance_count'])
                cols[1].metric("Type", requirements['instance_type'])
                cols[2].metric("Region", requirements['region'])
                cols[3].metric("Project", requirements['project_name'])
                
                st.markdown("### 🔧 Terraform Configuration")
                
                terraform_prompt = f"""Generate Terraform configuration for AWS EC2:
- {requirements['instance_count']} instances
- Type: {requirements['instance_type']}
- Region: {requirements['region']}
- Project: {requirements['project_name']}

Generate complete, working Terraform code. Include provider, security group, and EC2 resources.
Start with 'terraform {{' and include everything needed."""

                terraform_config = llm.invoke(terraform_prompt)
                
                st.code(terraform_config, language="hcl")
                
                st.download_button(
                    label="📥 Download main.tf",
                    data=terraform_config,
                    file_name="main.tf",
                    mime="text/plain"
                )
                
                tfvars = f"""aws_region = "{requirements['region']}"
project_name = "{requirements['project_name']}"
instance_type = "{requirements['instance_type']}"
instance_count = {requirements['instance_count']}

ssh_public_key_path = "~/.ssh/id_rsa.pub"
ssh_private_key_path = "~/.ssh/id_rsa"
"""
                
                st.markdown("### 📝 Variables File")
                st.code(tfvars, language="hcl")
                
                st.download_button(
                    label="📥 Download terraform.tfvars",
                    data=tfvars,
                    file_name="terraform.tfvars",
                    mime="text/plain"
                )
                
                st.markdown("### 🚀 Deployment Commands")
                commands = f"""# Deploy your infrastructure
terraform init
terraform plan
terraform apply -auto-approve

# View outputs
terraform output

# Destroy when done
terraform destroy -auto-approve
"""
                st.code(commands, language="bash")
                
            except Exception as e:
                st.error(f"❌ Error: {str(e)}")
                st.info("Make sure Ollama is running and accessible at the provided URL")

st.markdown("---")
st.markdown("""
<div style='text-align: center; color: #666;'>
    <p>💡 Tip: Make sure Ollama is running with llama3 model loaded</p>
    <p>Test Ollama: <code>curl http://localhost:11434/api/tags</code></p>
</div>
""", unsafe_allow_html=True)