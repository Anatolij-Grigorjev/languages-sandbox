RSpec.describe DeskEscalations::Mocks do
  describe "#escalate_ticket" do
    subject { described_class.escalate_ticket(ticket_id, escalation_type_code) }

    let(:ticket_id) { ticket.id }
    let(:escalation_type_code) { desk_escalation_type.code }
    let!(:ticket) do
      create(:ticket, :with_levels, ticket_queue: create(:ticket_queue, specialisation: ticket_specialisation))
    end

    let!(:service_provider) { create(:service_provider, :desk) }

    let!(:ticket_specialisation) { create(:specialisation) }
    let!(:desk_escalation_domain) { create(:desk_escalation_domain) }
    let!(:desk_escalation_type) { create(:desk_escalation_type, domain: desk_escalation_domain) }
    let!(:escalation_status) do
      create(:desk_escalation_status, :new)
    end

    it "creates an escalation case with provided type" do
      subject
      expect(DeskEscalationCase.count).to eq(1)
      expect(DeskEscalationCase.first.domain).to eq(desk_escalation_domain_shipping)
      expect(DeskEscalationCase.first.type).to eq(desk_escalation_type_shipping)
    end

    it "escalates ticket details according to ticket specialisation" do
      subject
      expect(DeskEscalationCaseTicketDetails.count).to eq(1)
      expect(DeskEscalationCaseTicketDetails.first.ticket_id).to eq(ticket_id)
      expect(DeskEscalationCaseTicketDetails.first.problem_level_id).to eq(ticket.leaf_level&.id)
    end

    it "adds marker detail about case being a mock" do
      subject
      expect(
        DeskEscalationCaseDetail.where(
          case_detail_type: "case_nature",
          case_detail_id: described_class::MOCK_NATURE_ID,
        ).count
      ).to eq(1)
    end

    it "creates case inputs for case view" do
      subject
      inputs = DeskEscalationCaseInputs.first
      expect(inputs).not_to be_nil
      expect(DeskEscalationCase.first.inputs_id).to eq(inputs.id)
    end

    context "when case type is in shipping domain" do
      let!(:desk_escalation_domain) { create(:desk_escalation_domain, :shipping_delivery) }

      it "adds a detail with shipping provider" do
        subject
        expect(
          DeskEscalationCaseDetails.where(
            case_detail_type: DeskEscalationCaseDetail::Type::SHIPPING_PROVIDER,
          ).count
        ).to eq(1)
      end

      it "will ensure one of the inputs is a shipping provider" do
        subject
        inputs = DeskEscalationCaseInputs.first
        expect(inputs.form_inputs_hash[:shipping_provider]).not_to be_nil
      end
    end

    context "when case type has issue types" do
      let!(:desk_escalation_type) { create(:desk_escalation_type, domain: desk_escalation_domain, issue_types: [issue_type]) }
      let(:issue_type) { create(:desk_escalation_issue_type) }

      it "adds a detail with issue type" do
        subject
        expect(
          DeskEscalationCaseDetails.where(
            case_detail_type: DeskEscalationCaseDetail::Type::ISSUE_TYPE,
          ).count
        ).to eq(1)
      end

      it "will ensure one of the inputs is an issue type" do
        subject
        inputs = DeskEscalationCaseInputs.first
        expect(inputs.form_inputs_hash[:issue_type]).not_to be_nil
      end
    end

    it "assigns priority based on type" do
      subject
      expect(DeskEscalationCase.first.priority).to eq(desk_escalation_type_shipping.priority)
    end

    it "adds ticket delegation update" do
      subject
      expect(TicketDelegationCase.count).to eq(1)
    end
  end
end
