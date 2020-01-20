# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
#
# This file is part of Action Server.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Action Server is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Action Server. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Action Server, please visit:
# https://github.com/openflighthpc/action-server
#===============================================================================

require 'spec_helper'

RSpec.describe NodeFacade::Standalone do
  it 'strips the __meta__ key from its list' do
    facade = described_class.new(__meta__: 'data')
    expect(facade[:__meta__]).to be_nil
  end
end

RSpec.describe NodeFacade do
  context 'when in an isolated standalone mode' do
    around do |e|
      with_facade_dummies do
        described_class.facade_instance = subject
        e.call
      end
    end

    let(:nodes_data) { {} }
    subject { described_class::Standalone.new(nodes_data) }

    describe '::find_by_name' do
      context 'with an empty set of nodes' do
        let(:nodes_data) { {} }

        it 'returns nil' do
          expect(described_class.find_by_name('missing')).to be_nil
        end
      end
    end
  end
end

