# frozen_string_literal: true

require 'activerecord-import'

# Wrap in a module so our classes don't leak out afterwards
module KafkaSourceSpec
  RSpec.describe Deimos::KafkaSource do
    before(:all) do
      ActiveRecord::Base.connection.create_table(:widgets, force: true) do |t|
        t.integer(:widget_id)
        t.string(:description)
        t.string(:model_id, default: '')
        t.string(:name)
        t.timestamps
      end
      ActiveRecord::Base.connection.add_index(:widgets, :widget_id)

      # Dummy producer which mimicks the behavior of a real producer
      class WidgetProducer < Deimos::ActiveRecordProducer
        topic 'my-topic'
        namespace 'com.my-namespace'
        schema 'Widget'
        key_config field: :id
      end

      # Dummy producer which mimicks the behavior of a real producer
      class WidgetProducerTheSecond < Deimos::ActiveRecordProducer
        topic 'my-topic-the-second'
        namespace 'com.my-namespace'
        schema 'WidgetTheSecond'
        key_config field: :id
      end

      # Dummy class we can include the mixin in. Has a backing table created
      # earlier.
      class Widget < ActiveRecord::Base
        include Deimos::KafkaSource

        # :nodoc:
        def self.kafka_producers
          [WidgetProducer, WidgetProducerTheSecond]
        end
      end
      Widget.reset_column_information

    end

    after(:all) do
      ActiveRecord::Base.connection.drop_table(:widgets)
    end

    before(:each) do
      Widget.delete_all
    end

    it 'should send events on creation, update, and deletion' do
      widget = Widget.create!(widget_id: 1, name: 'widget')
      expect('my-topic').to have_sent({
                                        widget_id: 1,
                                        name: 'widget',
                                        id: widget.id,
                                        created_at: anything,
                                        updated_at: anything
                                      }, 1)
      expect('my-topic-the-second').to have_sent({
                                                   widget_id: 1,
                                                   model_id: '',
                                                   id: widget.id,
                                                   created_at: anything,
                                                   updated_at: anything
                                                 }, 1)
      widget.update_attribute(:name, 'widget 2')
      expect('my-topic').to have_sent({
                                        widget_id: 1,
                                        name: 'widget 2',
                                        id: widget.id,
                                        created_at: anything,
                                        updated_at: anything
                                      }, 1)
      expect('my-topic-the-second').to have_sent({
                                                   widget_id: 1,
                                                   model_id: '',
                                                   id: widget.id,
                                                   created_at: anything,
                                                   updated_at: anything
                                                 }, 1)
      widget.destroy
      expect('my-topic').to have_sent(nil, 1)
      expect('my-topic-the-second').to have_sent(nil, 1)
    end

    it 'should not call generate_payload but still publish a nil payload for deletion' do
      widget = Widget.create!(widget_id: '808', name: 'delete_me!')
      expect(Deimos::ActiveRecordProducer).not_to receive(:generate_payload)
      widget.destroy
      expect('my-topic').to have_sent(nil, widget.id)
      expect('my-topic-the-second').to have_sent(nil, widget.id)
    end

    it 'should send events on import' do
      widgets = (1..3).map do |i|
        Widget.new(widget_id: i, name: "Widget #{i}")
      end
      Widget.import(widgets)
      widgets = Widget.all
      expect('my-topic').to have_sent({
                                        widget_id: 1,
                                        name: 'Widget 1',
                                        id: widgets[0].id,
                                        created_at: anything,
                                        updated_at: anything
                                      }, widgets[0].id)
      expect('my-topic').to have_sent({
                                        widget_id: 2,
                                        name: 'Widget 2',
                                        id: widgets[1].id,
                                        created_at: anything,
                                        updated_at: anything
                                      }, widgets[1].id)
      expect('my-topic').to have_sent({
                                        widget_id: 3,
                                        name: 'Widget 3',
                                        id: widgets[2].id,
                                        created_at: anything,
                                        updated_at: anything
                                      }, widgets[2].id)
    end

    it 'should send events even if the save fails' do
      widget = Widget.create!(widget_id: 1, name: 'widget')
      expect('my-topic').to have_sent({
                                        widget_id: 1,
                                        name: widget.name,
                                        id: widget.id,
                                        created_at: anything,
                                        updated_at: anything
                                      }, widget.id)
      clear_kafka_messages!
      Widget.transaction do
        widget.update_attribute(:name, 'widget 3')
        raise ActiveRecord::Rollback
      end
      expect('my-topic').to have_sent(anything)
    end

    it 'should not send events if an unrelated field changes' do
      widget = Widget.create!(widget_id: 1, name: 'widget')
      clear_kafka_messages!
      widget.update_attribute(:description, 'some description')
      expect('my-topic').not_to have_sent(anything)
    end

    context 'with DB backend' do
      before(:each) do
        Deimos.configure do |config|
          config.producers.backend = :db
        end
        setup_db(DB_OPTIONS.last) # sqlite
        allow(Deimos::Producer).to receive(:produce_batch).and_call_original
      end

      it 'should save to the DB' do
        Widget.create!(widget_id: 1, name: 'widget')
        expect(Deimos::KafkaMessage.count).to eq(2) # 2 producers
      end

      it 'should not save with a rollback' do
        Widget.transaction do
          Widget.create!(widget_id: 1, name: 'widget')
          raise ActiveRecord::Rollback
        end
        expect(Deimos::KafkaMessage.count).to eq(0)
      end
    end
  end
end
